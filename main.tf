provider "aws" {
  region = var.region
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
  pods = {
    for i in range(local.pod_count) : "pod-${i + 1}" => {
      index        = i
      id           = tostring(i + 1)
      name         = "pod-${i + 1}"
      org          = ""
      endpoint     = "https://store-pod-saas-gateway-${i + 1}.${data.aws_route53_zone.domain_zone.name}"
      namespace    = "store-pod-${i + 1}.${var.project}.lcl"
      size         = local.pod_size
      endpointType = "EXTERNAL"
    }
  }
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
  pods             = local.pods
  docker_registry  = local.docker_registry
  is_prod          = local.is_prod == "true"
  is_monitoring    = local.is_monitoring == "true"
  pod_auto_scale   = local.pod_auto_scale == "true"
}

module "store-pod" {
  source           = "git::https://github.com/cvhome-saas/cvhome-store-pod.git?ref=main"
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
  test_stores      = (each.key == "pod-1" && local.allow_test_stores == "true")
  pod              = each.value
  is_prod          = local.is_prod == "true"
  is_monitoring    = local.is_monitoring == "true"
  pod_auto_scale   = local.pod_auto_scale == "true"

  for_each = local.pods
}
