variable "aws_region" {

  default = "us-east-1"

}

variable "aws_availability_zones" {

  type = "list"

  default = ["us-east-1a", "us-east-1b", "us-east-1c"]

}

variable "ec2_ami" {

  default = "ami-0922553b7b0369273"

}

variable "instance_count" {

  type = "map"

  default = {

    "schema_registry"  =  1
    "rest_proxy"       =  0
    "kafka_connect"    =  1
    "ksql_server"      =  1
    "control_center"   =  1
    "bastion_server"   =  1
    "spring_server"    =  1
    "redis_server"     =  1
    "jaeger_server"    =  1
    "song_helper"      =  1

  }

}

variable "confluent_platform_location" {

  default = "http://packages.confluent.io/archive/5.2/confluent-5.2.1-2.12.zip"

}

variable "confluent_home_value" {

  default = "/etc/confluent/confluent-5.2.1"

}

variable "jaeger_tracing_location" {

  default = "https://github.com/jaegertracing/jaeger/releases/download/v1.10.0/jaeger-1.10.0-linux-amd64.tar.gz"

}
