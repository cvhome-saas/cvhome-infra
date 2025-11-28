output "store_ui_url" {
  value       = module.store-core.seller_ui_url
  description = "Store Ui URL"
}
output "core-auth_url" {
  value       = module.store-core.core-auth_url
  description = "Auth Ui URL"
}
output "pod_store_urls" {
  description = "Store URLs for default pods"
  value = {
    org1_store1 = "https://org1-store1.${module.store-pod.domain}"
    org1_store2 = "https://org1-store2.${module.store-pod.domain}"
    org2_store1 = "https://org2-store1.${module.store-pod.domain}"
    org2_store2 = "https://org2-store2.${module.store-pod.domain}"
  }
}
