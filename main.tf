resource "aws_iam_role" "lambda_role" {
  name = "Spacelift_Test_Lambda_Function_Role"
  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : "sts:AssumeRole",
          "Principal" : {
            "Service" : "lambda.amazonaws.com"
          },
          "Effect" : "Allow",
          "Sid" : ""
        }
      ]
  })

}

resource "aws_iam_policy" "iam_policy_for_lambda" {
  name        = "aws_iam_policy_for_terraform_aws_lambda_role"
  description = "AWS IAM Policy for managing aws lambda role"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      Resource = ["arn:aws:logs:*:*:*"]
      }, {
      Effect = "Allow"
      Action = [
        "ec2:CreateNetworkInterface",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DeleteNetworkInterface"
      ]
      Resource = ["*"]
    }]
  })
}


resource "aws_vpc" "example" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "example-vpc"
  }
}

resource "aws_subnet" "example" {
  cidr_block        = "10.0.1.0/24"
  vpc_id            = aws_vpc.example.id
  availability_zone = "us-east-1b"

  tags = {
    Name = "example-subnet"
  }
}

resource "aws_security_group" "example" {
  name_prefix = "example-sg"
  vpc_id      = aws_vpc.example.id

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["10.0.1.0/24"]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.iam_policy_for_lambda.arn
}

data "archive_file" "zip_the_python_code" {
  type        = "zip"
  source_dir  = "${path.module}/python/"
  output_path = "${path.module}/python/hello-python.zip"
}

resource "aws_lambda_function" "terraform_lambda_func" {
  function_name = "Spacelift_Test_Lambda_Function"
  filename      = "${path.module}/python/hello-python.zip"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_code.lambda_handler"
  runtime       = "python3.9"
  memory_size   = 1024
  timeout       = 300
  depends_on    = [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role]
  vpc_config {
    subnet_ids         = [aws_subnet.example.id]
    security_group_ids = [aws_security_group.example.id]
  }
}