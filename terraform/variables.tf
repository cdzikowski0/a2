variable "key" {

  type = string

  default = null

  description = "Pem key for AWS"

}

variable "postgres_user" {

  type = string

  default = null

  description = "Username for Postgres RDS"

}

variable "postgres_pass" {

  type = string

  default = null

  description = "Pw for Postgres RDS"

}
