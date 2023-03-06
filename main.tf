


  resource "aws_db_instance" "test_rds" {
    allocated_storage    = 10
    db_name              = "salonee_db"
    engine               = "mysql"
    engine_version       = "5.7"
    instance_class       = "db.t2.micro"
    username             = "salonee"
    password             = "salonee123"
    parameter_group_name = "default.mysql5.7"
    deletion_protection  = false
    skip_final_snapshot  = true
    final_snapshot_identifier = "myfinalsnapshot"
    vpc_security_group_ids = [ aws_security_group.test_rds_secgroup.id ]

    # Create a table named "my_table" with columns "col1", "col2", and "col3"
    provisioner "local-exec" {
      command = "mysql -h ${aws_db_instance.test_rds.endpoint} -P 3306 -u salonee -psalonee123 -e 'CREATE TABLE salonee_rds_table (id INT NOT NULL AUTO_INCREMENT, name VARCHAR(30) NOT NULL, PRIMARY KEY (id))';"
    }
  }

#   resource "aws_db_instance" "testing_rds" {
#     allocated_storage    = 10
#     engine               = "mysql"
#     engine_version       = "5.7"
#     instance_class       = "db.t2.micro"
#     name                 = "testing_rds"
#     username             = "salonee"
#     password             = "salonee123"
#     vpc_security_group_ids = [ aws_security_group.test_rds_secgroup.id ]
#   }

#   resource "aws_db_instance" "salonee_rds_table" {
#     name                 = "testing_rds"
#     username             = "salonee"
#     password             = "salonee123"
#     db_name              = "example_db"
#     vpc_security_group_ids = [ aws_security_group.test_rds_secgroup.id ]
#     provisioner "local-exec" {
#       command = "mysql -h ${aws_db_instance.testing_rds.endpoint} -P 3306 -u salonee_rds -p${aws_db_instance.testing_rds.password} -e 'CREATE TABLE salonee_rds_table (id INT NOT NULL AUTO_INCREMENT, name VARCHAR(30) NOT NULL, PRIMARY KEY (id))';"
#     }
#   }



resource "aws_security_group" "test_rds_secgroup" {
  name_prefix = "test-rds-"
  ingress {
    from_port = -1
    to_port   = -1
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# resource "aws_db_instance" "my_table" {
#   count = 1

#   db_name        = "test_db"
#   allocated_storage = 10
#   engine         = "mysql"
#   instance_class = "db.t2.micro"
#   identifier     = "my-table-${count.index}"
#   username       = "exampleuser"
#   password       = "examplepassword"
#   port           = 3306
#   skip_final_snapshot  = true
#   deletion_protection  = false

#   tags = {
#     Name = "my_table"
#   } 

#   provisioner "local-exec" {
#     command = "mysql -h ${aws_db_instance.test_rds.endpoint} -u salonee -p salonee123 -e 'CREATE TABLE my_table (col1 varchar(255), col2 varchar(255), col3 varchar(255));'"
#   }
# }


############################################################################################################
##                                                   S3                                                   ##
############################################################################################################

resource "aws_s3_bucket" "test_s3" {
  bucket = "leps3bucketfortest12"
  acl    = "private"
}

# Upload the CSV file to the S3 bucket
resource "aws_s3_bucket_object" "test_csv" {
  bucket = aws_s3_bucket.test_s3.id
  key    = "demofile.csv"
  source = "./demofile.csv.xlsx"
#   source = "C/:Userssalpandey/Downloads/demofile.csv" 
  depends_on = [
    aws_s3_bucket.test_s3
  ]
}

data "archive_file" "create_function_zip"{
type = "zip"
source_dir = "./lep-demo"
output_path = "./lambdademo.zip"
}

resource "aws_lambda_function" "test_lambda" {
#   source_code_hash = filemd5("./lambdademo.zip")  
  filename      = "./lambdademo.zip"  ##give full local path
  function_name = "test-function"
  role          = "arn:aws:iam::645240902082:role/LambdaRoleForS3andRDS"   ##Lambda exec role-- with permission for lambda to access s3, rds
  handler       = "lambdademo.lambda_handler"
  runtime       = "python3.7"

  environment {
    variables = {
      RDS_HOST     = aws_db_instance.rds_instance_demo.endpoint
      RDS_PORT     = aws_db_instance.rds_instance_demo.port
      RDS_DB_NAME  = aws_db_instance.rds_instance_demo.name
      RDS_USERNAME = aws_db_instance.rds_instance_demo.username
      RDS_PASSWORD = aws_db_instance.rds_instance_demo.password
      S3_BUCKET    = aws_s3_bucket.test_s3.id
      S3_KEY       = aws_s3_bucket_object.test_csv.key
    }
  }
  depends_on = [
    data.archive_file.create_function_zip
  ]
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

  schedule_expression = "cron(0 * * * ? *)"
}
