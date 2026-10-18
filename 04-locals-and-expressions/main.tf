data "aws_ami" "amazon_linux" {
    most_recent = true

    owners = ["amazon"]

    filter {
        name   = "name"
        values = ["al2023-ami-*-x86_64"]
    }

    filter {
        name   = "architecture"
        values = ["x86_64"]
    }
}

resource "aws_instance" "this" {
  ami = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"

  tags = merge(
    local.tags,
    {
        Name = local.instance_name
    }
  )
}

