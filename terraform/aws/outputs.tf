###########################################
################# Outputs #################
###########################################

output "Guess_Application" {
  value = "http://${aws_s3_bucket.the_song_is.website_endpoint}"
}

output "API_Gateway" {
  value = "${aws_api_gateway_deployment.guess_v1.invoke_url}${aws_api_gateway_resource.guess_resource.path}"
}

output "Kafka_Connect" {
  value = var.instance_count["kafka_connect"] >= 1 ? join(
    ",",
    formatlist("http://%s", aws_alb.kafka_connect.*.dns_name),
  ) : "Kafka Connect has been disabled"
}

output "KSQL_Server" {
  value = var.instance_count["ksql_server"] >= 1 ? join(",", formatlist("http://%s", aws_alb.ksql_server.*.dns_name)) : "KSQL Server has been disabled"
}

output "Jaeger_UI" {
  value = var.instance_count["jaeger_server"] >= 1 ? join(
    ",",
    formatlist("http://%s", aws_alb.jaeger_server.*.dns_name),
  ) : "Jaeger UI has been disabled"
}

output "Bastion_Server" {
  value = var.instance_count["bastion_server"] >= 1 ? "ssh ec2-user@${join(
    ",",
    formatlist("%s", aws_instance.bastion_server.*.public_ip),
  )} -i cert.pem" : "Bastion Server has been disabled"
}
