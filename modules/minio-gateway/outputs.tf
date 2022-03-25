output "minio_access_key" {
  value = random_password.minio_gateway_access_key
}

output "minio_secret_key" {
  value = random_password.minio_gateway_secret_key
}