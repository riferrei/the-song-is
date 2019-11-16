###########################################
################ Key Pair #################
###########################################

resource "tls_private_key" "key_pair" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = var.global_prefix
  public_key = tls_private_key.key_pair.public_key_openssh
}

resource "local_file" "private_key" {
  content  = tls_private_key.key_pair.private_key_pem
  filename = "cert.pem"
}

resource "null_resource" "private_key_permissions" {
  depends_on = [local_file.private_key]

  provisioner "local-exec" {
    command     = "chmod 600 cert.pem"
    interpreter = ["bash", "-c"]
    on_failure  = continue
  }
}

###########################################
############# Kafka Connect ###############
###########################################

resource "aws_instance" "kafka_connect" {
  depends_on = [
    aws_subnet.private_subnet,
    aws_nat_gateway.default,
  ]

  count         = var.instance_count["kafka_connect"]
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t3.2xlarge"
  key_name      = aws_key_pair.generated_key.key_name

  subnet_id              = element(aws_subnet.private_subnet.*.id, count.index)
  vpc_security_group_ids = [aws_security_group.kafka_connect[0].id]

  user_data = data.template_file.kafka_connect_bootstrap.rendered

  root_block_device {
    volume_type = "gp2"
    volume_size = 100
  }

  tags = {
    Name = "${var.global_prefix}-kafka-connect-${count.index}"
  }
}

###########################################
############## KSQL Server ################
###########################################

resource "aws_instance" "ksql_server" {
  depends_on = [
    aws_subnet.private_subnet,
    aws_nat_gateway.default,
  ]

  count         = var.instance_count["ksql_server"]
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t3.2xlarge"
  key_name      = aws_key_pair.generated_key.key_name

  subnet_id              = element(aws_subnet.private_subnet.*.id, count.index)
  vpc_security_group_ids = [aws_security_group.ksql_server[0].id]

  user_data = data.template_file.ksql_server_bootstrap.rendered

  root_block_device {
    volume_type = "gp2"
    volume_size = 300
  }

  tags = {
    Name = "${var.global_prefix}-ksql-server-${count.index}"
  }
}

###########################################
############ Bastion Server ###############
###########################################

resource "aws_instance" "bastion_server" {

  depends_on = [
    aws_instance.kafka_connect,
    aws_instance.ksql_server,
    aws_instance.song_helper,
  ]

  count = var.instance_count["bastion_server"] >= 1 ? 1 : 0

  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.generated_key.key_name

  subnet_id              = aws_subnet.bastion_server[0].id
  vpc_security_group_ids = [aws_security_group.bastion_server[0].id]

  user_data = data.template_file.bastion_server_bootstrap.rendered

  root_block_device {
    volume_type = "gp2"
    volume_size = 100
  }

  tags = {
    Name = "${var.global_prefix}-bastion-server"
  }
}

###########################################
############# Jaeger Server ###############
###########################################

resource "aws_instance" "jaeger_server" {
  depends_on = [
    aws_subnet.private_subnet,
    aws_nat_gateway.default,
  ]

  count = var.instance_count["jaeger_server"] >= 1 ? var.instance_count["jaeger_server"] : 1

  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t3.xlarge"
  key_name      = aws_key_pair.generated_key.key_name

  subnet_id              = element(aws_subnet.private_subnet.*.id, count.index)
  vpc_security_group_ids = [aws_security_group.jaeger_server[0].id]

  user_data = data.template_file.jaeger_server_bootstrap.rendered

  root_block_device {
    volume_type = "gp2"
    volume_size = 100
  }

  tags = {
    Name = "${var.global_prefix}-jaeger-server-${count.index}"
  }
}

###########################################
############## Song Helper ################
###########################################

resource "aws_instance" "song_helper" {
  depends_on = [aws_alb.ksql_server]

  count = var.instance_count["song_helper"]

  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t3.xlarge"
  key_name      = aws_key_pair.generated_key.key_name

  subnet_id              = element(aws_subnet.private_subnet.*.id, count.index)
  vpc_security_group_ids = [aws_security_group.song_helper[0].id]

  user_data = data.template_file.song_helper_bootstrap.rendered

  root_block_device {
    volume_type = "gp2"
    volume_size = 300
  }

  tags = {
    Name = "${var.global_prefix}-song-helper-${count.index}"
  }
}

###########################################
############# Redis Server ################
###########################################

resource "aws_instance" "redis_server" {
  depends_on = [
    aws_subnet.private_subnet,
    aws_nat_gateway.default,
  ]

  count = var.instance_count["redis_server"]

  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t3.xlarge"
  key_name      = aws_key_pair.generated_key.key_name

  subnet_id              = element(aws_subnet.private_subnet.*.id, count.index)
  vpc_security_group_ids = [aws_security_group.redis_server[0].id]

  user_data = data.template_file.redis_server_bootstrap.rendered

  root_block_device {
    volume_type = "gp2"
    volume_size = 300
  }

  tags = {
    Name = "${var.global_prefix}-redis-server-${count.index}"
  }
}

###########################################
########### Kafka Connect LBR #############
###########################################

resource "aws_alb_target_group" "kafka_connect_target_group" {
  count = var.instance_count["kafka_connect"] >= 1 ? 1 : 0

  name     = "${var.global_prefix}-kc-target-group"
  port     = "8083"
  protocol = "HTTP"
  vpc_id   = aws_vpc.default.id

  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 3
    interval            = 5
    path                = "/"
    port                = "8083"
  }
}

resource "aws_alb_target_group_attachment" "kafka_connect_attachment" {
  count = var.instance_count["kafka_connect"] >= 1 ? var.instance_count["kafka_connect"] : 0

  target_group_arn = aws_alb_target_group.kafka_connect_target_group[0].arn
  target_id        = element(aws_instance.kafka_connect.*.id, count.index)
  port             = 8083
}

resource "aws_alb" "kafka_connect" {
  depends_on = [aws_instance.kafka_connect]
  count      = var.instance_count["kafka_connect"] >= 1 ? 1 : 0

  name            = "${var.global_prefix}-kafka-connect"
  subnets         = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
  security_groups = [aws_security_group.load_balancer.id]
  internal        = false

  tags = {
    Name = "${var.global_prefix}-kafka-connect"
  }
}

resource "aws_alb_listener" "kafka_connect_listener" {
  count = var.instance_count["kafka_connect"] >= 1 ? 1 : 0

  load_balancer_arn = aws_alb.kafka_connect[0].arn
  protocol          = "HTTP"
  port              = "80"

  default_action {
    target_group_arn = aws_alb_target_group.kafka_connect_target_group[0].arn
    type             = "forward"
  }
}

###########################################
############# KSQL Server LBR #############
###########################################

resource "aws_alb_target_group" "ksql_server_target_group" {
  count = var.instance_count["ksql_server"] >= 1 ? 1 : 0

  name     = "${var.global_prefix}-ks-target-group"
  port     = "8088"
  protocol = "HTTP"
  vpc_id   = aws_vpc.default.id

  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 3
    interval            = 5
    path                = "/info"
    port                = "8088"
  }
}

resource "aws_alb_target_group_attachment" "ksql_server_attachment" {
  count = var.instance_count["ksql_server"] >= 1 ? var.instance_count["ksql_server"] : 0

  target_group_arn = aws_alb_target_group.ksql_server_target_group[0].arn
  target_id        = element(aws_instance.ksql_server.*.id, count.index)
  port             = 8088
}

resource "aws_alb" "ksql_server" {
  depends_on = [aws_instance.ksql_server]
  count      = var.instance_count["ksql_server"] >= 1 ? 1 : 0

  name            = "${var.global_prefix}-ksql-server"
  subnets         = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
  security_groups = [aws_security_group.load_balancer.id]
  internal        = false

  tags = {
    Name = "${var.global_prefix}-ksql-server"
  }
}

resource "aws_alb_listener" "ksql_server_listener" {
  count = var.instance_count["ksql_server"] >= 1 ? 1 : 0

  load_balancer_arn = aws_alb.ksql_server[0].arn
  protocol          = "HTTP"
  port              = "80"

  default_action {
    target_group_arn = aws_alb_target_group.ksql_server_target_group[0].arn
    type             = "forward"
  }
}

###########################################
########### Jaeger Server LBR #############
###########################################

resource "aws_alb_target_group" "jaeger_server_target_group" {
  name     = "${var.global_prefix}-js-target-group"
  port     = "16686"
  protocol = "HTTP"
  vpc_id   = aws_vpc.default.id

  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 3
    interval            = 5
    path                = "/"
    port                = "16686"
  }
}

resource "aws_alb_target_group_attachment" "jaeger_server_attachment" {
  count = var.instance_count["jaeger_server"] >= 1 ? var.instance_count["jaeger_server"] : 1

  target_group_arn = aws_alb_target_group.jaeger_server_target_group.arn
  target_id        = element(aws_instance.jaeger_server.*.id, count.index)
  port             = 16686
}

resource "aws_alb" "jaeger_server" {
  depends_on = [aws_instance.jaeger_server]

  name            = "${var.global_prefix}-jaeger-server"
  subnets         = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
  security_groups = [aws_security_group.load_balancer.id]
  internal        = false

  tags = {
    Name = "${var.global_prefix}-jaeger-server"
  }
}

resource "aws_alb_listener" "jaeger_server_listener" {
  load_balancer_arn = aws_alb.jaeger_server.arn
  protocol          = "HTTP"
  port              = "80"

  default_action {
    target_group_arn = aws_alb_target_group.jaeger_server_target_group.arn
    type             = "forward"
  }
}