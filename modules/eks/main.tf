locals {
  name_suffix         = var.environment_name != "prod" ? "-${var.environment_name}" : ""
  name_prefix         = var.name_prefix != "" ? "${var.name_prefix}-" : ""
  eks_cluster_name    = "${local.name_prefix}${var.eks_cluster_name}${local.name_suffix}-cluster"
  eks_node_group_name = "${local.name_prefix}${var.eks_cluster_name}${local.name_suffix}"

  # Base EKS addons that are always enabled
  base_cluster_addons = {
    coredns                = {}
    eks-pod-identity-agent = {}
    kube-proxy             = {}
    vpc-cni                = {}
  }

  # Conditional addon for EBS CSI Driver
  # Note: Applying the same pattern here for consistency and to avoid errors
  # if var.enable_aws_ebs_csi_driver_role is false, as module.aws_ebs_csi_irsa_role[0] wouldn't exist.
  ebs_csi_addon = var.enable_aws_ebs_csi_driver_role ? {
    aws-ebs-csi-driver = {
      # This reference is safe because it's only evaluated if the condition is true
      service_account_role_arn = module.aws_ebs_csi_irsa_role[0].iam_role_arn
    }
  } : {} # Use an empty map if disabled

  # Conditional addon for EFS CSI Driver (Your specific request)
  efs_csi_addon = var.enable_aws_efs_csi_driver_role ? {
    aws-efs-csi-driver = {
      # This reference is safe because it's only evaluated if the condition is true
      service_account_role_arn = module.aws_efs_csi_irsa_role[0].iam_role_arn
    }
  } : {} # Use an empty map if disabled

  # Merge all addons together
  final_cluster_addons = merge(
    local.base_cluster_addons,
    local.ebs_csi_addon,
    local.efs_csi_addon
  )

  # --- Configuration for S3 Sync IRSA ---
  s3_sync_role_name                = "s3-sync-role-${module.eks.cluster_name}" # Or any unique name
  s3_sync_policy_name_prefix       = "S3SyncPolicy-${module.eks.cluster_name}-"
  s3_sync_k8s_service_account_name = "s3-sync-sa" # The name of the K8s Service Account you will create
  s3_sync_k8s_service_account_ns   = "ethereum"   # The K8s namespace where the SA and pod will reside
  s3_source_bucket_name            = "domecloud-ethereum-config-dev"
  s3_source_bucket_arn             = "arn:aws:s3:::${local.s3_source_bucket_name}"
  s3_source_bucket_objects_arn     = "arn:aws:s3:::${local.s3_source_bucket_name}/*"

}

# EKS Cluster Module
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = local.eks_cluster_name
  cluster_version = var.eks_cluster_version

  # Optional
  cluster_endpoint_public_access = true

  # Optional: Adds the current caller identity as an administrator via cluster access entry
  enable_cluster_creator_admin_permissions = true

  # EKS Addons - Use the merged local map here
  cluster_addons = local.final_cluster_addons

  vpc_id     = var.vpc_id
  subnet_ids = var.vpc_private_subnets

  eks_managed_node_groups = {
    "${local.eks_node_group_name}" = {
      # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
      instance_types = var.instance_types
      ami_type       = var.ami_type

      min_size = var.node_group_min_size
      max_size = var.node_group_max_size
      # This value is ignored after the initial creation
      # https://github.com/bryantbiggs/eks-desired-size-hack
      desired_size = 2
    }
  }

  tags = {
    Name        = local.eks_cluster_name
    Environment = var.environment_name
  }
}

# IAM Roles for Service Accounts (IRSA) for AWS EBS CSI Driver
module "aws_ebs_csi_irsa_role" {
  count = var.enable_aws_ebs_csi_driver_role ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.55"

  role_name_prefix      = "${module.eks.cluster_name}-ebs-csi-irsa-"
  attach_ebs_csi_policy = true

  oidc_providers = {
    sts = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }

  tags = {
    Name        = "${module.eks.cluster_name}-ebs-csi-irsa"
    Environment = var.environment_name
  }

}

# IAM Roles for Service Accounts (IRSA) for AWS EFS CSI Driver
module "aws_efs_csi_irsa_role" {
  count = var.enable_aws_efs_csi_driver_role ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.55"

  role_name_prefix      = "${module.eks.cluster_name}-efs-csi-irsa-"
  attach_efs_csi_policy = true

  oidc_providers = {
    sts = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:efs-csi-controller-sa", "kube-system:efs-csi-node-sa"]
    }
  }


  tags = {
    Name        = "${module.eks.cluster_name}-efs-csi-irsa"
    Environment = var.environment_name
  }
}

# IAM Roles for Service Accounts (IRSA) for AWS Load Balancer Controller
module "aws_lbc_irsa_role" {
  count = var.enable_aws_lbc_role ? 1 : 0

  source           = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version          = "~> 5.55"
  role_name_prefix = "${module.eks.cluster_name}-lbc-irsa-"

  attach_load_balancer_controller_policy = true

  oidc_providers = {
    sts = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }

  tags = {
    Name        = "${module.eks.cluster_name}-lbc-irsa"
    Environment = var.environment_name
  }

}

# resource "null_resource" "wait_for_cluster" {
#   # Triggers ensure the provisioner re-runs if the cluster endpoint/ID changes.
#   triggers = {
#     cluster_endpoint = module.eks.cluster_endpoint
#     cluster_id       = module.eks.cluster_id
#     # Add any other output from module.eks that signifies cluster readiness
#   }

#   # Provisioner that runs locally to wait for the Kubernetes API
#   provisioner "local-exec" {
#     # This command assumes 'kubectl' is installed and configured
#     # to access your EKS cluster (e.g., via 'aws eks update-kubeconfig').
#     # It tries 'kubectl cluster-info' every 15 seconds for up to 5 minutes.
#     command     = <<EOT
#       echo "Waiting for Kubernetes cluster API server at ${module.eks.cluster_endpoint} to be ready..."
#       RETRIES=30
#       COUNT=0
#       # Use $$ to escape shell variables from Terraform interpolation
#       while [ $COUNT -lt $RETRIES ]; do
#         kubectl cluster-info > /dev/null 2>&1
#         if [ $? -eq 0 ]; then
#           echo "Cluster API server is ready."
#           exit 0
#         fi
#         COUNT=$((COUNT+1))
#         # Escape COUNT and RETRIES using $$
#         echo "Cluster not ready yet (attempt $${COUNT}/$${RETRIES}), sleeping for 15s..."
#         sleep 15
#       done

#       # Escape RETRIES using $$
#       echo "Error: Timeout waiting for cluster API server after $${RETRIES} attempts."
#       exit 1
#     EOT
#     interpreter = ["bash", "-c"]
#   }
# }

# Configure the Kubernetes provider using data from the EKS module
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  # Use AWS CLI to get authentication token
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    # Use the cluster name generated in your locals block
    args    = ["eks", "get-token", "--cluster-name", local.eks_cluster_name]
    command = "aws"
  }
}

# Optional: Configure Helm provider similarly if you use it
provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", local.eks_cluster_name]
      command     = "aws"
    }
  }
}

resource "kubernetes_storage_class" "gp3" {
  metadata {
    name = "gp3"
    # Optional: Add annotations to make this the default StorageClass
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }

  storage_provisioner    = "ebs.csi.aws.com"
  reclaim_policy         = "Delete"
  allow_volume_expansion = true
  volume_binding_mode    = "WaitForFirstConsumer" # Recommended: Waits until a pod needs the volume

  parameters = {
    type      = "gp3"  
    fsType    = "ext4"  
    encrypted = true 
    # You can add throughput/IOPS parameters for gp3 here if needed
    #iops       = 5700
    #throughput = 250
  }
}


# setup EFS file system
resource "aws_efs_file_system" "this" {
  count            = var.enable_aws_efs_csi_driver_role ? 1 : 0
  encrypted        = true
  performance_mode = "generalPurpose"

  tags = {
    Name        = "${local.eks_cluster_name}-bootstrap"
    Environment = var.environment_name
  }
}

resource "aws_efs_mount_target" "efs_mount" {
  count = var.enable_aws_efs_csi_driver_role ? length(var.vpc_private_subnets) : 0

  file_system_id  = aws_efs_file_system.this[0].id
  subnet_id       = var.vpc_private_subnets[count.index]
  security_groups = [aws_security_group.efs_security_group[0].id]
}

resource "aws_security_group" "efs_security_group" {
  count = var.enable_aws_efs_csi_driver_role ? 1 : 0

  name        = "efs-${local.eks_cluster_name}"
  description = "EFS security group"
  vpc_id      = var.vpc_id
}

resource "aws_security_group_rule" "allow_efs_2049" {
  count = var.enable_aws_efs_csi_driver_role ? 1 : 0

  type                     = "ingress"
  security_group_id        = aws_security_group.efs_security_group[0].id
  source_security_group_id = module.eks.node_security_group_id
  from_port                = 2049
  protocol                 = "tcp"
  to_port                  = 2049
}

# EFS CSI Driver Storage Class
resource "kubernetes_storage_class" "aws-efs-csi-driver" {
  count = var.enable_aws_efs_csi_driver_role ? 1 : 0
  metadata {
    name = "csi-efs"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "false"
    }
  }
  storage_provisioner    = "efs.csi.aws.com"
  reclaim_policy         = "Retain"
  volume_binding_mode    = "WaitForFirstConsumer"
  allow_volume_expansion = "true"
  parameters = {
    provisioningMode : "efs-ap"
    fileSystemId : aws_efs_file_system.this[0].id
    directoryPerms : "700"
  }
}


# IAM Policy Document granting read access to the specific S3 bucket
data "aws_iam_policy_document" "s3_sync_policy_doc" {
  statement {
    sid    = "AllowListBucket"
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      local.s3_source_bucket_arn # Permission to list the bucket contents
    ]
    # Optional: Add condition to restrict listing to specific prefixes if needed
    # condition {
    #   test     = "StringLike"
    #   variable = "s3:prefix"
    #   values   = ["path/to/sync/*", "another/path/*"]
    # }
  }

  statement {
    sid    = "AllowGetObject"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetObject"
    ]
    resources = [
      local.s3_source_bucket_objects_arn # Permission to get objects within the bucket
    ]
  }
}

# Create the IAM Policy from the document
resource "aws_iam_policy" "s3_sync_policy" {
  name_prefix = local.s3_sync_policy_name_prefix
  description = "Policy allowing s3:ListBucket and s3:GetObject for S3 sync IRSA"
  policy      = data.aws_iam_policy_document.s3_sync_policy_doc.json
}

module "iam_assumable_role_s3_sync" {
  source = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  # Use a specific version consistent with your project, v5.30.0 is recent as of late 2023/early 2024
  # Pinning to a specific minor version is generally safer for production
  version = "~> 5.30" # Or your existing version like "~> v2.6.0" if compatible

  create_role = true
  role_name   = local.s3_sync_role_name

  # List of IAM policy ARNs to attach to the role
  role_policy_arns = [
    aws_iam_policy.s3_sync_policy.arn
  ]

  # OIDC Provider URL from your EKS cluster - remove the "https://" prefix
  # Ensure module.eks.cluster_oidc_issuer_url provides the correct URL
  provider_url = replace(module.eks.cluster_oidc_issuer_url, "https://", "")

  # Define which Kubernetes Service Account can assume this role
  oidc_fully_qualified_subjects = [
    "system:serviceaccount:${local.s3_sync_k8s_service_account_ns}:${local.s3_sync_k8s_service_account_name}"
  ]

  tags = {
    Name        = local.s3_sync_role_name
    Environment = var.environment_name
  }
}

resource "helm_release" "alb_controller" {
  namespace = "kube-system"

  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.12.0"

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "region"
    value = var.aws_region
  }

  set {
    name  = "vpcId"
    value = var.vpc_id
  }

  depends_on = [
    kubernetes_service_account.aws_lbc_sa
  ]

}

resource "kubernetes_service_account" "aws_lbc_sa" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/name"      = "aws-load-balancer-controller"
      "app.kubernetes.io/component" = "controller"
    }
    annotations = {
      "eks.amazonaws.com/role-arn"               = module.aws_lbc_irsa_role[0].iam_role_arn
      "eks.amazonaws.com/sts-regional-endpoints" = "true"
    }
  }
}
