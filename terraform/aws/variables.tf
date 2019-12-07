locals {
  region = split(".", var.ccloud_broker_list)[1]
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "amazon_linux_2" {
 most_recent = true
 owners      = ["amazon"]
 filter {
   name   = "owner-alias"
   values = ["amazon"]
 }
 filter {
   name   = "name"
   values = ["amzn2-ami-hvm*"]
 }
}

variable "instance_count" {
  type = map(string)
  default = {
    "kafka_connect"  = 1
    "ksql_server"    = 1
    "bastion_server" = 1
    "redis_server"   = 1
    "jaeger_server"  = 1
    "song_helper"    = 1
  }
}

variable "confluent_platform_location" {
  default = "http://packages.confluent.io/archive/5.3/confluent-5.3.1-2.12.zip"
}

variable "confluent_home_value" {
  default = "/etc/confluent/confluent-5.3.1"
}

variable "jaeger_tracing_location" {
  default = "https://github.com/jaegertracing/jaeger/releases/download/v1.13.0/jaeger-1.13.0-linux-amd64.tar.gz"
}
