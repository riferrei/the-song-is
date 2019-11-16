variable "bucket_suffix" {
  default = "riferrei"
}

resource "aws_s3_bucket" "the_song_is" {
  bucket = "the-song-is-${var.bucket_suffix}"
  acl    = "public-read"

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "POST"]
    allowed_origins = ["*"]
  }

  policy = <<EOF
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::the-song-is-${var.bucket_suffix}/*"
        }
    ]
}
    
EOF


  website {
    index_document = "index.html"
    error_document = "error.html"
  }
}

data "template_file" "index_html" {
  template = file("templates/index.html")

  vars = {
    guess_api_endpoint = "${aws_api_gateway_deployment.guess_v1.invoke_url}${aws_api_gateway_resource.guess_resource.path}"
  }
}

resource "aws_s3_bucket_object" "index" {
  bucket = aws_s3_bucket.the_song_is.bucket
  key = "index.html"
  content_type = "text/html"
  content = data.template_file.index_html.rendered
}

resource "aws_s3_bucket_object" "error" {
  bucket = aws_s3_bucket.the_song_is.bucket
  key = "error.html"
  content_type = "text/html"
  source = "./templates/error.html"
}

resource "aws_s3_bucket_object" "logo" {
  bucket = aws_s3_bucket.the_song_is.bucket
  key = "apache-kafka.png"
  content_type = "image/png"
  source = "./templates/apache-kafka.png"
}

resource "aws_s3_bucket_object" "logo2" {
  bucket = aws_s3_bucket.the_song_is.bucket
  key = "serverless.jpg"
  content_type = "image/jpg"
  source = "./templates/serverless.jpg"
}

data "template_file" "redis_connector" {
  template = file("templates/redisConnector.json")

  vars = {
    redis_hosts = "${join(
      ",",
      formatlist("%s", aws_instance.redis_server.*.private_ip),
    )}:6379"
  }
}

resource "local_file" "redis_connector" {
  content = data.template_file.redis_connector.rendered
  filename = "redisConnector.json"
}

data "template_file" "initialize_script" {
  template = file("templates/initialize.sh")

  vars = {
    kafka_connect_url = join(
      ",",
      formatlist("http://%s", aws_alb.kafka_connect.*.dns_name),
    )
    ksql_server_url = join(",", formatlist("http://%s", aws_alb.ksql_server.*.dns_name))
  }
}

resource "local_file" "initialize_script" {
  content = data.template_file.initialize_script.rendered
  filename = "initialize.sh"
}

data "template_file" "do_delete_keys_script" {
  template = file("templates/doDeleteKeys.sh")

  vars = {
    redis_host = join(
      ",",
      formatlist("%s", aws_instance.redis_server.*.private_ip),
    )
    redis_port = "6379"
  }
}

resource "local_file" "do_delete_keys_script" {
  content = data.template_file.do_delete_keys_script.rendered
  filename = "doDeleteKeys.sh"
}

resource "null_resource" "do_delete_keys_permissions" {
  depends_on = [local_file.do_delete_keys_script]
  provisioner "local-exec" {
    command = "chmod 775 doDeleteKeys.sh"
    interpreter = ["bash", "-c"]
    on_failure = continue
  }
}

data "template_file" "delete_keys_script" {
  template = file("templates/deleteKeys.sh")

  vars = {
    bastion_server = join(
      ",",
      formatlist("%s", aws_instance.bastion_server.*.public_ip),
    )
  }
}

resource "local_file" "delete_keys_script" {
  content = data.template_file.delete_keys_script.rendered
  filename = "deleteKeys.sh"
}

resource "null_resource" "delete_keys_permissions" {
  depends_on = [local_file.delete_keys_script]
  provisioner "local-exec" {
    command = "chmod 775 deleteKeys.sh"
    interpreter = ["bash", "-c"]
    on_failure = continue
  }
}
