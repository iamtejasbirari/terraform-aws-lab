# ---------------------------------------------------------
# Data Source
# ---------------------------------------------------------
# Terraform does not create this AMI.
# It queries AWS and reads information about an existing AMI.

data "aws_ami" "amazon_linux" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}


# ---------------------------------------------------------
# Resource
# ---------------------------------------------------------
# Terraform creates and manages this EC2 instance.

resource "aws_instance" "example" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"

  tags = {
    Name = "terraform-data-source-demo"
  }
}