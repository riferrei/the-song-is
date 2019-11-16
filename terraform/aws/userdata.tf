###########################################
######## Kafka Connect Bootstrap ##########
###########################################

data "template_file" "kafka_connect_properties" {
  template = file("../util/kafka-connect.properties")
  vars = {
    broker_list                = var.ccloud_broker_list
    access_key                 = var.ccloud_access_key
    secret_key                 = var.ccloud_secret_key
    global_prefix              = var.global_prefix
    confluent_home_value       = var.confluent_home_value
    schema_registry_url        = var.ccloud_schema_registry_url
    schema_registry_basic_auth = var.ccloud_schema_registry_basic_auth
  }
}

data "template_file" "kafka_connect_bootstrap" {
  template = file("../util/kafka-connect.sh")
  vars = {
    jaeger_tracing_location = var.jaeger_tracing_location
    jaeger_collector = join(
      ",",
      formatlist("%s:%s", aws_instance.jaeger_server.*.private_ip, "14267"),
    )
    confluent_platform_location = var.confluent_platform_location
    kafka_connect_properties    = data.template_file.kafka_connect_properties.rendered
    confluent_home_value        = var.confluent_home_value
  }
}

###########################################
######### KSQL Server Bootstrap ###########
###########################################

data "template_file" "ksql_server_properties" {
  template = file("../util/ksql-server.properties")
  vars = {
    broker_list                = var.ccloud_broker_list
    access_key                 = var.ccloud_access_key
    secret_key                 = var.ccloud_secret_key
    global_prefix              = var.global_prefix
    confluent_home_value       = var.confluent_home_value
    schema_registry_url        = var.ccloud_schema_registry_url
    schema_registry_basic_auth = var.ccloud_schema_registry_basic_auth
  }
}

data "template_file" "ksql_server_bootstrap" {
  template = file("../util/ksql-server.sh")
  vars = {
    jaeger_tracing_location = var.jaeger_tracing_location
    jaeger_collector = join(
      ",",
      formatlist("%s:%s", aws_instance.jaeger_server.*.private_ip, "14267"),
    )
    confluent_platform_location = var.confluent_platform_location
    ksql_server_properties      = data.template_file.ksql_server_properties.rendered
    confluent_home_value        = var.confluent_home_value
  }
}

###########################################
############# Redis Bootstrap #############
###########################################

data "template_file" "redis_config" {
  template = file("../util/redis.conf")
}

data "template_file" "redis_server_bootstrap" {
  template = file("../util/redis-server.sh")
  vars = {
    redis_config = data.template_file.redis_config.rendered
  }
}

###########################################
######### Jaeger Server Bootstrap #########
###########################################

data "template_file" "jaeger_server_bootstrap" {
  template = file("../util/jaeger-server.sh")
  vars = {
    jaeger_tracing_location = var.jaeger_tracing_location
  }
}

###########################################
########## Song Helper Bootstrap ##########
###########################################

data "template_file" "song_helper_bootstrap" {
  template = file("../util/song-helper.sh")
  vars = {
    broker_list   = var.ccloud_broker_list
    access_key    = var.ccloud_access_key
    secret_key    = var.ccloud_secret_key
    client_id     = var.spotify_client_id
    client_secret = var.spotify_client_secret
    access_token  = var.spotify_access_token
    refresh_token = var.spotify_refresh_token
  }
}

###########################################
######## Bastion Server Bootstrap #########
###########################################

data "template_file" "bastion_server_bootstrap" {
  template = file("../util/bastion-server.sh")
  vars = {
    private_key_pem = tls_private_key.key_pair.private_key_pem
    kafka_connect_addresses = join(" ", formatlist("%s", aws_instance.kafka_connect.*.private_ip))
    ksql_server_addresses = join(" ", formatlist("%s", aws_instance.ksql_server.*.private_ip))
    song_helper_addresses = join(" ", formatlist("%s", aws_instance.song_helper.*.private_ip))
  }

}