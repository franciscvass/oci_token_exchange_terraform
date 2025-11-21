output "idcs_endpoint" {
  value = oci_identity_domains_app.this.idcs_endpoint
}


output "client_id" {
  value = oci_identity_domains_app.this.name
}

output "client_secret" {
  value = oci_identity_domains_app.this.client_secret
}

output "app_ocid" {
  value = oci_identity_domains_app.this.ocid
}

output "user_ocid" {
  value = oci_identity_domains_user.this.ocid
}

output "user_id" {
  value = oci_identity_domains_user.this.id
}

output "group" {
  value = oci_identity_domains_group.this
}

