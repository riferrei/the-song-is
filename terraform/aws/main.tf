###########################################
################## AWS ####################
###########################################

provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = local.region
}

variable "aws_access_key" {
}

variable "aws_secret_key" {
}

###########################################
############# Confluent Cloud #############
###########################################

variable "ccloud_broker_list" {
}

variable "ccloud_access_key" {
}

variable "ccloud_secret_key" {
}

variable "ccloud_schema_registry_url" {
}

variable "ccloud_schema_registry_basic_auth" {
}

###########################################
################## Others #################
###########################################

variable "global_prefix" {
  default = "the-song-is"
}

variable "winner_skill_id" {
}

variable "delete_keys_skill_id" {
}

variable "spotify_client_id" {
}

variable "spotify_client_secret" {
}

variable "spotify_access_token" {
}

variable "spotify_refresh_token" {
}
