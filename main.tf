provider "aws" {
  region = "eu-north-1"
  profile = "default"
}

resource "aws_s3_bucket" "my_bucket" {
  bucket = "this-my-bucket-n1"
}
resource "aws_s3_bucket" "my_bucket1" {
  bucket = "this-my-bucket-n2"
}
resource "aws_iam_role" "lambda_role" {
  name = "lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}
data "archive_file" "zip_python" {
  type        = "zip"
  source_dir  = "${path.module}/python1/"
  output_path = "${path.module}/python1/python1.zip"
}
resource "aws_iam_policy" "lambda_policy" {
  name = "lambda_policy_1"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::this-my-bucket-n1/*",
          "arn:aws:s3:::this-my-bucket-n2/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:PutLogEvents",
          "logs:CreateLogGroup",
          "logs:CreateLogStream"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "lambda_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}
resource "aws_lambda_function" "my_lambda" {
  function_name = "s3-2"
  role          = aws_iam_role.lambda_role.arn
  handler       = "python1.lambda_handler"
  runtime       = "python3.12"
  filename      = "${path.module}/python1/python1.zip"
  environment {
    variables = {
      BUCKET_N1 = aws_s3_bucket.my_bucket.bucket 
      BUCKET_N2 = aws_s3_bucket.my_bucket1.bucket
    }
  }
}
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.my_bucket.id
  lambda_function {
    lambda_function_arn = aws_lambda_function.my_lambda.arn
    events              = ["s3:ObjectCreated:*"]
  }
}



resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.my_lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.my_bucket.arn
}