#!/bin/bash

# run TF Output
terraform output > .tfout
# Define the path to the Terraform output file
terraform_output_file=".tfout"

# Define the path to the Ansible inventory file
ansible_inventory_file="inventory.ini"

# Read the Terraform output file and extract the IP addresses and master IP
ip_addresses=($(awk -F '"' '/^django_ips/ {getline; while ($0 !~ /^\s*]$/) {gsub(/,$/, ""); print; getline}}' "$terraform_output_file"))
master_ip=$(awk -F '"' '/^master_ip/ {print $2}' "$terraform_output_file")

# Add the master IP to the inventory file with a label
echo "[master_server]" > "$ansible_inventory_file"
echo "django_master ansible_host=$master_ip" >> "$ansible_inventory_file"

# Create the Ansible inventory file
echo "[django_servers]" >> "$ansible_inventory_file"

# Append each IP address to the inventory file with a label
for index in "${!ip_addresses[@]}"; do
    echo "django$index ansible_host=${ip_addresses[$index]}" >> "$ansible_inventory_file"
done

# Append Django Vars
echo "[django_Servers:vars]" >> $ansible_inventory_file
echo "ansible_ssh_private_key_file=/home/ec2-user/ansible/key.pem" >> $ansible_inventory_file


# Print a success message
echo "Ansible inventory file created successfully!"

# Copy Inventory ini to Master
scp -i /home/dizz/.ssh/cp_devops_dzikowski.pem -o StrictHostKeyChecking=accept-new inventory.ini ec2-user@$master_ip:/home/ec2-user/ansible/

scp -i /home/dizz/.ssh/cp_devops_dzikowski.pem -o StrictHostKeyChecking=accept-new /home/dizz/.ssh/cp_devops_dzikowski.pem ec2-user@$master_ip:/home/ec2-user/ansible/key.pem

 # Print a success message
echo "Files copied Successfully!"

# Clean up
rm .tfout inventory.ini