################################################################################
# Basic EKS Cluster Setup with Security and Logging
################################################################################


variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "The version of the EKS cluster"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the EKS cluster"
  type        = list(string)
}

variable "vpc_id" {
  description = "ID of the VPC where the cluster security group will be provisioned"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "cluster_tags" {
  description = "Additional tags for the EKS cluster"
  type        = map(string)
  default     = {}
}

variable "cluster_security_group_tags" {
  description = "Tags for the cluster security group"
  type        = map(string)
  default     = {}
}

variable "create_cluster_security_group" {
  description = "Determines if a security group is created for the cluster"
  type        = bool
  default     = true
}

variable "create_iam_role" {
  description = "Determines whether an IAM role is created or to use an existing IAM role"
  type        = bool
  default     = true
}

variable "iam_role_name" {
  description = "Name of the IAM role"
  type        = string
}

variable "iam_role_description" {
  description = "Description of the IAM role"
  type        = string
}

variable "iam_role_permissions_boundary" {
  description = "ARN of the policy that is used to set the permissions boundary for the IAM role"
  type        = string
  default     = null
}

variable "iam_role_tags" {
  description = "Tags for the IAM role"
  type        = map(string)
  default     = {}
}

variable "create_cloudwatch_log_group" {
  description = "Determines whether a log group is created by this module for the cluster logs"
  type        = bool
  default     = true
}

variable "cloudwatch_log_group_retention_in_days" {
  description = "Number of days to retain log events"
  type        = number
  default     = 90
}

variable "enable_kms_key_rotation" {
  description = "Specifies whether key rotation is enabled"
  type        = bool
  default     = true
}

variable "kms_key_enable_default_policy" {
  description = "Specifies whether to enable the default key policy"
  type        = bool
  default     = true
}

variable "cluster_encryption_policy_tags" {
  description = "Tags for the encryption policy"
  type        = map(string)
  default     = {}
}

variable "cluster_addons" {
  description = "Map of cluster addon configurations to enable for the cluster"
  type        = map(object({
    addon_version             = string
    configuration_values      = map(string)
    preserve                  = bool
    resolve_conflicts_on_create = string
    resolve_conflicts_on_update = string
    service_account_role_arn  = string
    timeouts                  = object({
      create = string
      update = string
      delete = string
    })
    tags                      = map(string)
  }))
  default     = {}
}

variable "cluster_identity_providers" {
  description = "Map of identity provider configurations for the cluster"
  type        = map(object({
    client_id                     = string
    groups_claim                  = string
    groups_prefix                 = string
    identity_provider_config_name = string
    issuer_url                    = string
    required_claims               = list(string)
    username_claim                = string
    username_prefix               = string
    tags                          = map(string)
  }))
  default     = {}
}