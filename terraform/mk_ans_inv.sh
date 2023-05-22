#!/bin/bash

# Define the path to the Terraform output file
terraform_output_file=".tfout"

# Define the path to the Ansible inventory file
ansible_inventory_file="inventory.ini"

# Run TF Output and save the output to a file
terraform output > "$terraform_output_file"

# Read the Terraform output file and extract the IP addresses and master IP
ip_addresses=($(awk -F '"' '/^django_ips/ {getline; while ($0 !~ /^\s*]$/) {gsub(/,$/, ""); print; getline}}' "$terraform_output_file"))
master_ip=$(awk -F '"' '/^master_ip/ {print $2}' "$terraform_output_file")

# Create the Ansible inventory file
echo "[master_server]" > "$ansible_inventory_file"
echo "django_master ansible_host=$master_ip" >> "$ansible_inventory_file"
echo "[django_servers]" >> "$ansible_inventory_file"

# Append each IP address to the inventory file with a label and ansible_user and ssh settings
for index in "${!ip_addresses[@]}"; do
    echo "django$index ansible_host=${ip_addresses[$index]} ansible_user=ec2-user ansible_ssh_common_args='-o StrictHostKeyChecking=accept-new'" >> "$ansible_inventory_file"
done

# Append Django Vars
echo "[django_servers:vars]" >> "$ansible_inventory_file"
echo "ansible_ssh_private_key_file=/home/ec2-user/ansible/key.pem" >> "$ansible_inventory_file"

# Print a success message
echo "Ansible inventory file created successfully!"

# Generate nginx.conf.j2 file

nginx_conf_template="events {}
http {
    upstream backend {
        {% for host in groups['django_servers'] %}
        server {{ hostvars[host].ansible_host }}:9876;
        {% endfor %}
    }

    server {
        listen 80;
        server_name {{ master_ip }};

        location / {
            proxy_pass http://backend;
            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host \$host;
            proxy_cache_bypass \$http_upgrade;
        }
    }

}"

# Replace template variables with actual values
nginx_conf_content="${nginx_conf_template//\{\{ master_ip \}\}/$master_ip}"

# Save the generated nginx.conf.j2 file
echo "$nginx_conf_content" > nginx.conf.j2

# Print a success message
echo "nginx.conf.j2 file created successfully!"

# Copy Inventory files to Master
scp -i /home/dizz/.ssh/cp_devops_dzikowski.pem -o StrictHostKeyChecking=accept-new "$ansible_inventory_file" ec2-user@"$master_ip":/home/ec2-user/ansible/
scp -i /home/dizz/.ssh/cp_devops_dzikowski.pem -o StrictHostKeyChecking=accept-new /home/dizz/.ssh/cp_devops_dzikowski.pem ec2-user@"$master_ip":/home/ec2-user/ansible/key.pem
scp -i /home/dizz/.ssh/cp_devops_dzikowski.pem -o StrictHostKeyChecking=accept-new ../ansible/playbook.yaml ec2-user@"$master_ip":/home/ec2-user/ansible/playbook.yaml
scp -i /home/dizz/.ssh/cp_devops_dzikowski.pem -o StrictHostKeyChecking=accept-new ../.env ec2-user@"$master_ip":/home/ec2-user/.env
scp -i /home/dizz/.ssh/cp_devops_dzikowski.pem -o StrictHostKeyChecking=accept-new ../todo.service ec2-user@"$master_ip":/home/ec2-user/
scp -i /home/dizz/.ssh/cp_devops_dzikowski.pem -o StrictHostKeyChecking=accept-new nginx.conf.j2 ec2-user@"$master_ip":/home/ec2-user/

# Print a success message
echo "Files copied successfully!"

# Clean up
rm "$terraform_output_file" "$ansible_inventory_file" nginx.conf.j2
