variable "internal_dns_root_domain" {
  type = string
  # default = "example-internal.com"
  description = "This is the internal DNS root domain used for service discovery and issuing certificates within a VPC."
}

variable "public_dns_name" {
  type = string
  # default = "example.com"
  description = "The DNS domain name that will serve the Ghost website. This can be like `example.com` or `subdomain.example.com`."
}

variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "The AWS region to deploy the Ghost website to."
}

variable "internal_dns_subdomain" {
  type        = string
  default     = "ghost"
  description = "This is a namespace for this Provose Terraform module. It lets you share the same internal root domain across multiple Provose Terraform modules."
}

variable "ghost_version" {
  type        = string
  default     = "3.40.5"
  description = "The version of Ghost to deploy. Always pick an exact version for the sake of stability, but continually check for new versions of Ghost. You can find valid versions on Docker Hub at https://hub.docker.com/_/ghost"
}