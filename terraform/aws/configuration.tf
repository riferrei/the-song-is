data "template_file" "config_properties" {

  template = "${file("templates/config.properties")}"

  vars {

    broker_list = "${var.ccloud_broker_list}"
    access_key = "${var.ccloud_access_key}"
    secret_key = "${var.ccloud_secret_key}"

  }

}

resource "null_resource" "local_config" {

    provisioner "local-exec" {

        command = "rm ~/.ccloud/config"
        interpreter = ["bash", "-c"]
        on_failure = "continue"

    }

    provisioner "local-exec" {

        command = "echo '${data.template_file.config_properties.rendered}' >> ~/.ccloud/config"
        interpreter = ["bash", "-c"]
        on_failure = "continue"

    }

    provisioner "local-exec" {

        command = "ccloud topic create CURRENT_SONG --partitions 4 --replication-factor 3"
        on_failure = "continue"

    }

    provisioner "local-exec" {

        command = "ccloud topic create TWEETS --partitions 4 --replication-factor 3"
        on_failure = "continue"

    }

    provisioner "local-exec" {

        command = "ccloud topic create GUESSES --partitions 4 --replication-factor 3"
        on_failure = "continue"

    }

}

data "template_file" "twitter_connector" {

  template = "${file("templates/twitterConnector.json")}"

  vars {

    filter_keywords = "${var.filter_keywords}"
    twitter_oauth_access_token = "${var.twitter_oauth_access_token}"
    twitter_oauth_access_token_secret = "${var.twitter_oauth_access_token_secret}"
    twitter_oauth_consumer_key = "${var.twitter_oauth_consumer_key}"
    twitter_oauth_consumer_secret = "${var.twitter_oauth_consumer_secret}"

  }

}

resource "local_file" "twitter_connector" {

  content  = "${data.template_file.twitter_connector.rendered}"
  filename = "twitterConnector.json"

}

data "template_file" "redis_connector" {

  template = "${file("templates/redisConnector.json")}"

  vars {

    redis_hosts = "${join(",", formatlist("%s", aws_instance.redis_server.*.private_ip))}:6379"

  }

}

resource "local_file" "redis_connector" {

  content  = "${data.template_file.redis_connector.rendered}"
  filename = "redisConnector.json"

}

data "template_file" "initialize_script" {

  template = "${file("templates/initialize.sh")}"

  vars {

    kafka_connect_url = "${join(",", formatlist("http://%s", aws_alb.kafka_connect.*.dns_name))}"
    ksql_server_url   = "${join(",", formatlist("http://%s", aws_alb.ksql_server.*.dns_name))}"

  }

}

resource "local_file" "initialize_script" {

  content  = "${data.template_file.initialize_script.rendered}"
  filename = "initialize.sh"
  
}

data "template_file" "song_helper_script" {

  template = "${file("templates/song-helper.sh")}"

  vars {

    broker_list = "${var.ccloud_broker_list}"
    access_key = "${var.ccloud_access_key}"
    secret_key = "${var.ccloud_secret_key}"

    client_id = "${var.spotify_client_id}"
    client_secret = "${var.spotify_client_secret}"

  }

}

resource "local_file" "song_helper_script" {

  content  = "${data.template_file.song_helper_script.rendered}"
  filename = "song-helper.sh"
  
}

resource "null_resource" "song_helper_script_permissions" {

    depends_on = ["local_file.song_helper_script"]
    provisioner "local-exec" {

        command = "chmod 775 song-helper.sh"
        interpreter = ["bash", "-c"]
        on_failure = "continue"

    }

}

data "template_file" "do_delete_keys_script" {

  template = "${file("templates/doDeleteKeys.sh")}"

  vars {

    redis_host = "${join(",", formatlist("%s", aws_instance.redis_server.*.private_ip))}"
    redis_port = "6379"

  }

}

resource "local_file" "do_delete_keys_script" {

  content  = "${data.template_file.do_delete_keys_script.rendered}"
  filename = "doDeleteKeys.sh"
  
}

resource "null_resource" "do_delete_keys_permissions" {

    depends_on = ["local_file.do_delete_keys_script"]
    provisioner "local-exec" {

        command = "chmod 775 doDeleteKeys.sh"
        interpreter = ["bash", "-c"]
        on_failure = "continue"

    }

}

data "template_file" "delete_keys_script" {

  template = "${file("templates/deleteKeys.sh")}"

  vars {

    bastion_server = "${join(",", formatlist("%s", aws_instance.bastion_server.*.public_ip))}"

  }

}

resource "local_file" "delete_keys_script" {

  content  = "${data.template_file.delete_keys_script.rendered}"
  filename = "deleteKeys.sh"
  
}

resource "null_resource" "delete_keys_permissions" {

    depends_on = ["local_file.delete_keys_script"]
    provisioner "local-exec" {

        command = "chmod 775 deleteKeys.sh"
        interpreter = ["bash", "-c"]
        on_failure = "continue"

    }

}