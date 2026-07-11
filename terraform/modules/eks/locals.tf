locals {
  cluster_tags = merge({ Name = var.cluster_name }, var.tags)
  node_tags    = merge({ Name = "${var.cluster_name}-nodes" }, var.tags)
}