################################################################################
# Basic EKS Cluster Setup with Security and Logging
################################################################################

resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = aws_iam_role.main.arn

  vpc_config {
    subnet_ids          = var.subnet_ids
    security_group_ids  = [
      aws_security_group.cluster.id,
    ]
  }

  version = var.cluster_version

  tags = merge(var.tags, var.cluster_tags)
}

resource "aws_security_group" "cluster" {
  count       = var.create_cluster_security_group ? 1 : 0
  name        = "eks-cluster-sg"
  description = "Security group for EKS cluster"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, var.cluster_security_group_tags)
}

resource "aws_iam_role" "main" {
  count              = var.create_iam_role ? 1 : 0
  name               = var.iam_role_name
  description        = var.iam_role_description
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
  permissions_boundary = var.iam_role_permissions_boundary

  tags = merge(var.tags, var.iam_role_tags)
}

resource "aws_iam_role_policy_attachment" "main" {
  for_each = var.create_iam_role ? {
    AmazonEKSClusterPolicy         = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
    AmazonEKSVPCResourceController = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  } : {}

  policy_arn = each.value
  role       = aws_iam_role.main.name
}

resource "aws_iam_policy" "cluster_encryption" {
  count = var.enable_kms_key_rotation ? 1 : 0

  name        = "eks-cluster-encryption-policy"
  description = "Policy for EKS cluster encryption"
  path        = "/"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["kms:Encrypt", "kms:Decrypt", "kms:ListGrants", "kms:DescribeKey"]
        Effect   = "Allow"
        Resource = var.create_kms_key ? module.kms.key_arn : var.cluster_encryption_config.provider_key_arn
      }
    ]
  })

  tags = merge(var.tags, var.cluster_encryption_policy_tags)
}

resource "aws_eks_addon" "main" {
  for_each = var.cluster_addons

  cluster_name       = aws_eks_cluster.main.name
  addon_name         = each.key
  addon_version      = try(each.value.addon_version, null)
  configuration_values = try(each.value.configuration_values, null)
  preserve           = try(each.value.preserve, true)
  resolve_conflicts_on_create = try(each.value.resolve_conflicts_on_create, "OVERWRITE")
  resolve_conflicts_on_update = try(each.value.resolve_conflicts_on_update, "OVERWRITE")
  service_account_role_arn = try(each.value.service_account_role_arn, null)

  timeouts {
    create = try(each.value.timeouts.create, null)
    update = try(each.value.timeouts.update, null)
    delete = try(each.value.timeouts.delete, null)
  }

  tags = merge(var.tags, try(each.value.tags, {}))
}

resource "aws_eks_identity_provider_config" "main" {
  for_each = var.cluster_identity_providers

  cluster_name = aws_eks_cluster.main.name

  oidc {
    client_id                     = each.value.client_id
    groups_claim                  = lookup(each.value, "groups_claim", null)
    groups_prefix                 = lookup(each.value, "groups_prefix", null)
    identity_provider_config_name = each.key
    issuer_url      = each.value.issuer_url
    required_claims = lookup(each.value, "required_claims", null)
    username_claim  = lookup(each.value, "username_claim", null)
    username_prefix = lookup(each.value, "username_prefix", null)
  }

  tags = merge(var.tags, try(each.value.tags, {}))
}