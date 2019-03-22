###########################################
################## AWS ####################
###########################################

provider "aws" {

    access_key = "${var.aws_access_key}"
    secret_key = "${var.aws_secret_key}"
    region = "${var.aws_region}"
  
}

variable "aws_access_key" {}

variable "aws_secret_key" {}

###########################################
############# Confluent Cloud #############
###########################################

variable "ccloud_broker_list" {}

variable "ccloud_access_key" {}

variable "ccloud_secret_key" {}

###########################################
################## Others #################
###########################################

variable "global_prefix" {

    default = "the-song-is"
    
}

variable "the_song_is_skill_id" {}
variable "delete_keys_skill_id" {}
variable "spotify_client_id" {}
variable "spotify_client_secret" {}
variable "spotify_access_token" {}
variable "spotify_refresh_token" {}
variable "spotify_device_name" {}

variable "filter_keywords" {}
variable "twitter_oauth_access_token" {}
variable "twitter_oauth_access_token_secret" {}
variable "twitter_oauth_consumer_key" {}
variable "twitter_oauth_consumer_secret" {}