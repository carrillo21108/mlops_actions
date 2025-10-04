variable "prefix" { type = string }
variable "image_repo" { type = string }
variable "image_tag" { type = string }
variable "root_path" { type = string }
variable "run_id" { type = string }
variable "network_name" { type = string }

variable "raw_volume_name" { type = string }
variable "silver_volume_name" { type = string }
variable "gold_volume_name" { type = string }
variable "features_volume_name" { type = string }
variable "models_volume_name" { type = string }

variable "train_command" {
  type = list(string)
}

variable "env_extra" {
  type    = map(string)
  default = {}
}
