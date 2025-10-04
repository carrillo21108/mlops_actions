#########################################
# Volúmenes de datos y red compartida   #
#########################################

resource "docker_volume" "raw" { name = "${var.prefix}_raw" }
resource "docker_volume" "silver" { name = "${var.prefix}_silver" }
resource "docker_volume" "gold" { name = "${var.prefix}_gold" }
resource "docker_volume" "features" { name = "${var.prefix}_features" }
resource "docker_volume" "models" { name = "${var.prefix}_models" }

resource "docker_network" "analytics" {
  name = "${var.prefix}_analytics_net"
}

output "raw_volume"      { value = docker_volume.raw.name }
output "silver_volume"   { value = docker_volume.silver.name }
output "gold_volume"     { value = docker_volume.gold.name }
output "features_volume" { value = docker_volume.features.name }
output "models_volume"   { value = docker_volume.models.name }
output "network_name"    { value = docker_network.analytics.name }
