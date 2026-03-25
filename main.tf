provider "aws" {
  region = var.region
}

resource "random_id" "pod_id" {
  for_each    = { for i in range(local.pod_count) : "pod-${i + 2}" => i }
  byte_length = 12
}

data "aws_caller_identity" "current" {}

data "aws_route53_zone" "domain_zone" {
  zone_id = local.hosted_zone_id
}

data "aws_acm_certificate" "certificate" {
  domain   = data.aws_route53_zone.domain_zone.name
  statuses = ["ISSUED"]
}

locals {
  store_core_namespace = "store-core.${var.project}.lcl"
  tags = {
    Project     = var.project
    Terraform   = "true"
    Environment = local.env
  }
  docker_registry = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.project}"
  extra_pods_id = {
    for k, v in random_id.pod_id :
    k => {
      id         = v.hex
      shorten_id = substr(v.hex, 0, 15)
    }
  }
  default_pods_id = {
    "pod-1" = {
      id         = "507f1f77bcf86cd799439011"
      shorten_id = substr("507f1f77bcf86cd799439011", 0, 15)
    }
  }
  extra_pods = {
    for i in range(local.pod_count) : "pod-${i + 2}" => {
      index             = i + 1
      id                = local.extra_pods_id["pod-${i + 2}"].id
      shorten_pod_id    = local.extra_pods_id["pod-${i + 2}"].shorten_id
      pod_record_prefix = "spg-" + local.extra_pods_id["pod-${i + 2}"].shorten_id
      name              = "pod-" + local.extra_pods_id["pod-${i + 2}"].shorten_id
      org               = ""
      endpoint          = "https://spg-" + local.extra_pods_id["pod-${i + 2}"].shorten_id + ".${data.aws_route53_zone.domain_zone.name}"
      namespace         = "store-pod-" + local.extra_pods_id["pod-${i + 2}"].shorten_id + ".${var.project}.lcl"
      size              = local.pod_size
      endpointType      = "EXTERNAL"
    }
  }
  default_pod = {
    index             = 0
    id                = local.default_pods_id["pod-1"].id
    shorten_pod_id    = local.default_pods_id["pod-1"].shorten_id
    pod_record_prefix = "spg-" + local.default_pods_id["pod-1"].shorten_id
    name              = "pod-" + local.default_pods_id["pod-1"].shorten_id
    org               = ""
    endpoint          = "https://spg-" + local.default_pods_id["pod-1"].shorten_id + ".${data.aws_route53_zone.domain_zone.name}"
    namespace         = "store-pod-" + local.default_pods_id["pod-1"].shorten_id + ".${var.project}.lcl"
    size              = local.pod_size
    endpointType      = "EXTERNAL"
  }
  all_pods = merge(local.extra_pods, {
    "pod-1" : local.default_pod
  })
}


module "store-core" {
  source           = "./store-core"
  vpc_id           = module.vpc.vpc_id
  public_subnets   = module.vpc.public_subnets
  private_subnets  = module.vpc.private_subnets
  log_s3_bucket_id = module.log-bucket.s3_bucket_id
  domain           = data.aws_route53_zone.domain_zone.name
  certificate_arn  = data.aws_acm_certificate.certificate.arn
  project          = var.project
  tags             = local.tags
  database_subnets = module.vpc.database_subnets
  vpc_cidr_block   = local.vpc_cidr
  env              = local.env
  region           = var.region
  image_tag        = local.image_tag
  namespace        = local.store_core_namespace
  pods             = local.all_pods
  docker_registry  = local.docker_registry
  is_prod          = local.is_prod == "true"
  is_monitoring    = local.is_monitoring == "true"
  pod_auto_scale   = local.pod_auto_scale == "true"
}

module "store-pod" {
  source           = "git::https://github.com/cvhome-saas/cvhome-store-pod.git?ref=feat/dynamic-pod"
  vpc_id           = module.vpc.vpc_id
  public_subnets   = module.vpc.public_subnets
  private_subnets  = module.vpc.private_subnets
  log_s3_bucket_id = module.log-bucket.s3_bucket_id
  domain           = data.aws_route53_zone.domain_zone.name
  domain_zone_name = data.aws_route53_zone.domain_zone.name
  project          = var.project
  tags             = local.tags
  database_subnets = module.vpc.database_subnets
  vpc_cidr_block   = local.vpc_cidr
  env              = local.env
  region           = var.region
  docker_registry  = local.docker_registry
  image_tag        = local.image_tag
  test_stores      = true
  pod              = local.default_pod
  is_prod          = local.is_prod == "true"
  is_monitoring    = local.is_monitoring == "true"
  pod_auto_scale   = local.pod_auto_scale == "true"
}

module "store-pod-n" {
  source           = "git::https://github.com/cvhome-saas/cvhome-store-pod.git?ref=feat/dynamic-pod"
  vpc_id           = module.vpc.vpc_id
  public_subnets   = module.vpc.public_subnets
  private_subnets  = module.vpc.private_subnets
  log_s3_bucket_id = module.log-bucket.s3_bucket_id
  domain           = data.aws_route53_zone.domain_zone.name
  domain_zone_name = data.aws_route53_zone.domain_zone.name
  project          = var.project
  tags             = local.tags
  database_subnets = module.vpc.database_subnets
  vpc_cidr_block   = local.vpc_cidr
  env              = local.env
  region           = var.region
  docker_registry  = local.docker_registry
  image_tag        = local.image_tag
  test_stores      = false
  pod              = each.value
  is_prod          = local.is_prod == "true"
  is_monitoring    = local.is_monitoring == "true"
  pod_auto_scale   = local.pod_auto_scale == "true"

  for_each = local.extra_pods
}
