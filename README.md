# Deploy a Ghost website with Provose

Provose is the easiest way to manage your Amazon Web Services infrastructure.

Ghost is a modern, open-source, and easy-to-use platform for building a website, blog, or subscription newsletter.

## Installation requirements

This is a summary of the installation details in [the official Provose tutorial](https://provose.com/v3.0/tutorial).

1. Make sure your local system has [Terraform 0.13 or newer](https://learn.hashicorp.com/tutorials/terraform/install-cli) and [the AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html).
2. Make sure your system has AWS credentials that Terraform can find. On a local machine, you can use environment variables or [a `~/.aws/credentials` file](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html). On an AWS EC2 instance, Terraform can use the [instance's IAM instance profile](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use_switch-role-ec2_instance-profiles.html).
3. You will need a domain name to host your Ghost website. Provose requires a second domain name for the purpose of issuing TLS certificates and routing internal traffic in the Virtual Private Cloud (VPC) that Provose creates.

### Run Terraform

Then clone this repository with

```
git clone git@github.com:provose/provose-ghost-website-example.git
cd provose-ghost-website-example
```

Then set up your workspace with

```
terraform init
```

Then run
```
terraform apply
```

If you have multiple AWS profiles on your system, you may need to specify the profile with an environment variables as follows:
```
AWS_PROFILE=my_profile_2 terraform apply
```

Terraform will interactively prompt you for your two domain names. You can also set these Terraform variables as [command line arguments](https://www.terraform.io/docs/commands/apply.html#var-39-foo-bar-39-) or [environment variables](https://www.terraform.io/docs/configuration/variables.html#environment-variables).

It will take several minutes for your infrastructure to deploy. At the end, Terraform should print a message that starts with `Apply complete!`.

If you have set up this infrastructure for testing and now want to destroy it, you can run:
```
terraform destroy
```

Make sure to disable Deletion Protection on the MySQL database if you are sure that you want to delete it.

## Exercises for the reader

### Adding a Content Delivery Network (CDN)

This example sets up a single Docker container running on AWS Fargate, sitting behind an Application Load Balancer (ALB). For further scalability, the ALB should be behind a Content Delivery Network (CDN) like Cloudflare or AWS CLoudFront.

### Enabling email

This example sets up Ghost, but without any credentials for sending transactional emails--for example, in case the admin forgets their password.

It is possible to configure Amazon Simple Email Service (SES) and pass those credentials to Ghost. More details can be found [here](https://ksick.dev/using-amazon-ses-to-send-mails-from-a-ghost-blog/).

### Using a SQLite3 database

Typically the Ghost blogging platform is backed via a MySQL database, but SQLite is another option. Switching to SQLite might be a way for blogs with low traffic to save on their cloud costs.