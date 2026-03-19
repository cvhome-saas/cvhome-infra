locals {
  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      description = "HTTP web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
    all_https = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      description = "HTTPS web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = var.vpc_cidr_block
    }
  }
}
module "cluster-lb" {
  source = "terraform-aws-modules/alb/aws"

  name                       = "${local.module_name}-${var.project}-${var.env}"
  vpc_id                     = var.vpc_id
  subnets                    = var.public_subnets
  enable_deletion_protection = false



  access_logs = {
    bucket = var.log_s3_bucket_id
    prefix = "${local.module_name}-lb-access-logs"
  }

  # Security Group
  security_group_ingress_rules = local.security_group_ingress_rules
  security_group_egress_rules  = local.security_group_egress_rules


  listeners = {
    ex-http-https-redirect = {
      port     = 80
      protocol = "HTTP"
      redirect = {
        protocol    = "HTTPS"
        port        = "443"
        status_code = "HTTP_301"
      }

    }

    ex-fallback-response = {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = var.certificate_arn
      fixed_response = {
        content_type = "text/plain"
        message_body = "ALB not matched any routes"
        status_code  = "404"
      }
      rules = {
        uaa-forward = {
          priority = 1
          actions = [
            {
              forward = {
                target_group_key = "uaa-tg"
              }
            }
          ]
          conditions = [
            {
              host_header = {
                values = ["uaa.${var.domain}"]
              }
            }
          ]
        }
        core-forward = {
          priority = 2
          actions = [
            {
              forward = {
                target_group_key = "gateway-tg"
              }
            }
          ]
          conditions = [
            {
              host_header = {
                values = [var.domain, "www.${var.domain}", "seller-ui.${var.domain}"]
              }
            }
          ]
        }
      }
    }
  }

  target_groups = {
    uaa-tg = {
      create_attachment = false
      name_prefix       = "c-a"
      protocol          = "HTTP"
      port              = 8001
      target_type       = "ip"

      health_check = {
        enabled             = true
        interval            = 45
        path                = "/actuator/health"
        port                = 8001
        healthy_threshold   = 2
        unhealthy_threshold = 5
        timeout             = 5
        protocol            = "HTTP"
        matcher             = "200"
      }
    }
    gateway-tg = {
      create_attachment = false
      name_prefix       = "c-g"
      protocol          = "HTTP"
      port              = 8000
      target_type       = "ip"

      health_check = {
        enabled             = true
        interval            = 45
        path                = "/actuator/health"
        port                = 8000
        healthy_threshold   = 2
        unhealthy_threshold = 5
        timeout             = 5
        protocol            = "HTTP"
        matcher             = "200"
      }
    }
  }

  tags = var.tags
}
module "root-record" {
  source  = "terraform-aws-modules/route53/aws//modules/records"
  version = "~> 3.0"

  zone_name = var.domain

  records = [
    {
      name = ""
      type = "A"
      alias = {
        name    = module.cluster-lb.dns_name
        zone_id = module.cluster-lb.zone_id
      }
    }
  ]
}

module "www-record" {
  source  = "terraform-aws-modules/route53/aws//modules/records"
  version = "~> 3.0"

  zone_name = var.domain

  records = [
    {
      name = "www"
      type = "A"
      alias = {
        name    = module.cluster-lb.dns_name
        zone_id = module.cluster-lb.zone_id
      }
    }
  ]
}

module "uaa-record" {
  source  = "terraform-aws-modules/route53/aws//modules/records"
  version = "~> 3.0"

  zone_name = var.domain

  records = [
    {
      name = "uaa"
      type = "A"
      alias = {
        name    = module.cluster-lb.dns_name
        zone_id = module.cluster-lb.zone_id
      }
    }
  ]
}
module "seller-ui-record" {
  source  = "terraform-aws-modules/route53/aws//modules/records"
  version = "~> 3.0"

  zone_name = var.domain

  records = [
    {
      name = "seller-ui"
      type = "A"
      alias = {
        name    = module.cluster-lb.dns_name
        zone_id = module.cluster-lb.zone_id
      }
    }
  ]
}