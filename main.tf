# We use Terraform to generate the master password for a new
# AWS Aurora MySQL database. We secure this password in AWS Secrets Manager
# but another copy ends up existing in your Terraform state file.
resource "random_password" "ghost_mysql_master_password" {
  # the maximum AWS RDS password length is 41 characters
  length           = 41
  override_special = "()-_=+[]{}<>?"
}

# This is a Provose module. It can create many resources that live together
# in the same AWS Virtual Private Cloud (VPC). If you want to isolate resources
# into separate VPCs, create separate modules.
module "ghost" {
  # Run this with Provose 3.0.0. The `source` can also point to a path on the
  # local filesystem if you would like to point your Provose modules to a local copy.
  source = "github.com/provose/provose?ref=v3.0.0"
  provose_config = {
    authentication = {
      aws = {
        region = var.aws_region
      }
    }
    name                 = var.internal_dns_subdomain
    internal_root_domain = var.internal_dns_root_domain
    internal_subdomain   = var.internal_dns_subdomain
  }
  # Set up an AWS Aurora MySQL database as the backing relational store for the
  # Ghost website.
  mysql_clusters = {
    ghost-db = {
      engine_version = "5.7.mysql_aurora.2.07.2"
      database_name  = "ghost"
      password       = random_password.ghost_mysql_master_password.result
      # By default, Provose enables AWS RDS Deletion Protection on databases.
      # This means that Provose/Terraform cannot destroy the databases that it
      # creates... unless you pass this below configuration setting that will
      # disable deletion protection.
      # deletion_protection = false
      instances = {
        instance_type  = "db.t2.small"
        instance_count = 1
      }
    }
  }
  # Store the database password in AWS Secrets Manager to pass to the Ghost
  # container.
  secrets = {
    ghost_mysql_master_password = random_password.ghost_mysql_master_password.result
  }
  # Set up an AWS Elastic File System to stores images, themes, and other uploads
  # for the website.
  elastic_file_systems = {
    ghost-efs = {}
  }
  # Run the Ghost application container, connecting it to the above Aurora MySQL database
  # and the Elastic File System.
  containers = {
    ghost = {
      image = {
        name             = "ghost"
        tag              = var.ghost_version
        private_registry = false
      }
      public = {
        # This sets up an AWS Application Load Balancer, reverse-proxying HTTPS
        # traffic to the application containers. The ALB is given an
        # automatically-configuredd AWS Certificate Manager (ACM) certificate
        # for "var.public_dns_name".
        https = {
          internal_http_port                              = 2368
          public_dns_names                                = [var.public_dns_name]
          internal_http_health_check_path                 = "/robots.txt"
          internal_http_health_check_success_status_codes = "200,301"
        }
      }
      instances = {
        instance_type = "FARGATE"
        # Currently, Ghost is not well desiged to run as a multi-container setup.
        # To serve more traffic, it is better to put the Application Load Balancer
        # behind a CDN like AWS CloudFront.
        container_count = 1
        cpu             = 1024
        memory          = 2048
      }
      # Here we mount the AWS EFS mount to this path in the container, where
      # images and themes are stored.
      efs_volumes = {
        ghost-efs = {
          container_mount = "/var/lib/ghost/content"
        }
      }
      # Here is where we tell the Ghost container how to connect to our
      # AWS Aurora MySQL database.
      environment = {
        url              = "https://${var.public_dns_name}"
        database__client = "mysql"
        # Take note of how we construct internal DNS names in Provose.
        # The MySQL database's DNS name is its Provose name followed by the
        # internal subdomain and internal root domain.
        database__connection__host     = "ghost-db.${var.internal_dns_subdomain}.${var.internal_dns_root_domain}"
        database__connection__user     = "root"
        database__connection__database = "ghost"
      }
      # The container will see this as a regular environment variable, but the
      # secret is stored and encrypted in AWS Secrets Manager. This secret also exists
      # in the Terraform state for this project--which is why it is important to use
      # an encrypted S3 bucket for storing state for this project.
      secrets = {
        database__connection__password = "ghost_mysql_master_password"
      }
    }
  }
}
