data "aws_ssm_parameter" "config-cvhome" {
  name = "/${var.project}/config/cvhome"
}

locals {
  hosted_zone_id    = nonsensitive(jsondecode(data.aws_ssm_parameter.config-cvhome.value).hosted_zone_id)
  env               = nonsensitive(jsondecode(data.aws_ssm_parameter.config-cvhome.value).env)
  image_tag         = nonsensitive(jsondecode(data.aws_ssm_parameter.config-cvhome.value).image_tag)
  pod_ids           = nonsensitive(jsondecode(data.aws_ssm_parameter.config-cvhome.value).pod_ids)
  pod_size          = nonsensitive(jsondecode(data.aws_ssm_parameter.config-cvhome.value).pod_size)
  pod_auto_scale    = nonsensitive(jsondecode(data.aws_ssm_parameter.config-cvhome.value).pod_auto_scale)
  is_prod           = nonsensitive(jsondecode(data.aws_ssm_parameter.config-cvhome.value).is_prod)
  is_monitoring     = nonsensitive(jsondecode(data.aws_ssm_parameter.config-cvhome.value).is_monitoring)
  allow_test_stores = nonsensitive(jsondecode(data.aws_ssm_parameter.config-cvhome.value).allow_test_stores)
}
