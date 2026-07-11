resource "aws_eks_cluster" "eks_cluster" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster.arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids              = var.cluster_subnet_ids
    endpoint_public_access  = var.endpoint_public_access
    endpoint_private_access = var.endpoint_private_access
  }

  enabled_cluster_log_types = var.enable_cluster_log_types

  depends_on = [aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy]

  tags = local.cluster_tags
}

resource "aws_cloudwatch_log_group" "cluster" {
  count             = length(var.enable_cluster_log_types) > 0 ? 1 : 0
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = 7
  tags              = local.cluster_tags
}