output "cluster_name" {
    value = aws_eks_cluster.eks_cluster.name
}

output "cluster_endpoint" {
    value = aws_eks_cluster.eks_cluster.endpoint
}

output "cluster_certificate_authority_data" {
    value = aws_eks_cluster.eks_cluster.certificate_authority[0].data
}

output "cluster_security_group_id" {
    value = aws_eks_cluster.eks_cluster.vpc_config[0].security_group_ids[0]
}

output "cluster_oidc_issuer_url" {
    value = aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer
}

output "cluster_oidc_thumbprint" {
    value = data.tls_certificate.eks_cluster.certificates[0].sha1_fingerprint
}

output "cluster_oidc_provider_arn" {
    value = aws_iam_openid_connect_provider.eks_cluster.arn
}