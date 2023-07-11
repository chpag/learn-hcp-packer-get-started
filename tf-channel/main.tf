provider "hcp" {}

provider "aws" {
  region = var.region
}

data "hcp_packer_iteration" "ubuntu" {
  bucket_name = "learn-packer-ubuntu"
  channel     = "production"
}

data "hcp_packer_image" "ubuntu_us_east_2" {
  bucket_name    = "learn-packer-ubuntu"
  cloud_provider = "aws"
  iteration_id   = data.hcp_packer_iteration.ubuntu.ulid
  region         = "us-east-2"
}

resource "aws_instance" "app_server" {
  ami           = data.hcp_packer_image.ubuntu_us_east_2.cloud_image_id
  instance_type = "t2.micro"
  tags = {
    Name = "Learn-HCP-Packer"
  }
}

check "latest_ami" {
  # Workaround for check{} blocks currently evaluating against the future
  # state of the resource: use current state instead, from a data source
  data "aws_instance" "app_server1" {
    # Can't use instance_id either, because in the case of a newer AMI, that ID is going to change too
    # instance_id = aws_instance.web.id

    # So instead... just give me all the EC2 instances in this VPC
    # That's okay for this use-case, but not generalisable
    filter {
      name   = "tag:Name"
      values = ["Learn-HCP-Packer"]
    }
  }

  assert {
    condition     = data.aws_instance.app_server1.ami == data.hcp_packer_image.ubuntu_us_east_2.cloud_image_id
    error_message = "Must use the latest available AMI, ${data.hcp_packer_image.ubuntu_us_east_2.cloud_image_id}."
  }
}
