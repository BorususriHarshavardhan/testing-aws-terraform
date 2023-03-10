provider "aws" {
  region = "us-east-1"
}


resource "aws_db_instance" "test_rds" {
  allocated_storage    = 10
  db_name              = "test_db"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t3.micro"
  username             = "salonee"
  password             = "salonee123"
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
}

resource "aws_security_group" "test_rds_secgroup" {
  name_prefix = "test-rds-"
  ingress {
    from_port = 3306
    to_port   = 3306
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# # Create a table named "my_table" with columns "col1", "col2", and "col3"
# provisioner "local-exec" {
#   command = <<EOT
#     mysql -h ${aws_db_instance.example.endpoint} -u ${var.username} -p${var.password} -e "
#       CREATE TABLE my_table (
#         col1 VARCHAR(255),
#         col2 VARCHAR(255),
#         col3 VARCHAR(255)
#       );
#   EOT
# }

############################################################################################################
##                                                   S3                                                   ##
############################################################################################################

resource "aws_s3_bucket" "test_s3" {
  bucket = "example-bucket"
  acl    = "private"
}

# Upload the CSV file to the S3 bucket
resource "aws_s3_bucket_object" "test_csv" {
  bucket = aws_s3_bucket.test_s3.id
  key    = "test_csv.csv"
  source = "path/to/test_s3.csv"
}

resource "aws_lambda_function" "test_lambda" {
  filename      = "test_lambda_function.zip"
  function_name = "test-function"
  role          = "arn:aws:iam::123456789012:role/lambda-role"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.7"

  environment {
    variables = {
      RDS_HOST     = aws_db_instance.test_rds.endpoint
      RDS_PORT     = aws_db_instance.test_rds.port
      RDS_DB_NAME  = aws_db_instance.test_rds.name
      RDS_USERNAME = aws_db_instance.test_rds.username
      RDS_PASSWORD = aws_db_instance.test_rds.password
      S3_BUCKET    = aws_s3_bucket.test_s3.id
      S3_KEY       = aws_s3_bucket_object.test_s3.key
    }
  }
}
# Define the code for the Lambda function
// import csv
// import os
// import boto3
// import pymysql

// # Configuration options
// S3_BUCKET_NAME = 'my-s3-bucket'
// S3_OBJECT_KEY = 'my-csv-file.csv'
// RDS_HOST = 'my-rds-host.amazonaws.com'
// RDS_PORT = 3306
// RDS_USER = 'my-rds-username'
// RDS_PASSWORD = 'my-rds-password'
// RDS_DATABASE = 'my-rds-database'

// # Create S3 and RDS clients
// s3 = boto3.client('s3')
// rds = pymysql.connect(host=RDS_HOST, port=RDS_PORT, user=RDS_USER, password=RDS_PASSWORD, database=RDS_DATABASE)

// def lambda_handler(event, context):
//     # Download the CSV file from S3
//     s3.download_file(S3_BUCKET_NAME, S3_OBJECT_KEY, '/tmp/my-csv-file.csv')

//     # Parse the CSV file and update the RDS database
//     with open('/tmp/my-csv-file.csv', newline='') as csvfile:
//         reader = csv.reader(csvfile)
//         next(reader)  # skip header row
//         for row in reader:
//             cursor = rds.cursor()
//             cursor.execute('INSERT INTO my_table (col1, col2, col3) VALUES (%s, %s, %s)', (row[0], row[1], row[2]))
//             rds.commit()
//             cursor.close()

//     # Return success
//     return {
//         'statusCode': 200,
//         'body': 'CSV file successfully processed'
//     }


// }

# Create a CloudWatch event rule to trigger the Lambda function every hour
resource "aws_cloudwatch_event_rule" "example" {
  name        = "example-rule"
  description = "Trigger the example Lambda function every hour"

  schedule_expression = "cron(0 * * *)"
}
