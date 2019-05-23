data "template_file" "serverless_configuration" {
  template = file("templates/serverless.yml")

  vars = {
    redis_host = join(
      ",",
      formatlist("%s", aws_instance.redis_server.*.private_ip),
    )
    redis_port           = "6379"
    the_song_is_skill_id = var.the_song_is_skill_id
    delete_keys_skill_id = var.delete_keys_skill_id
    security_group_id    = aws_security_group.redis_server[0].id
    private_subnet_0     = aws_subnet.private_subnet[0].id
    private_subnet_1     = aws_subnet.private_subnet[1].id
    private_subnet_2     = aws_subnet.private_subnet[2].id
  }
}

resource "local_file" "serverless_configuration" {
  content  = data.template_file.serverless_configuration.rendered
  filename = "../../serverless/serverless.yml"
}

