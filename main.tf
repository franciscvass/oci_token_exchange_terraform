resource "oci_identity_domains_app" "this" {
  force_delete = true
  active                  = var.app_active
  all_url_schemes_allowed = false
  allow_access_control    = false
  allowed_grants          = var.allowed_grants
  allowed_operations      = var.allowed_operations
  dynamic "allowed_scopes" {
    for_each = var.allowed_scopes != [] ? var.allowed_scopes : []
    iterator = as
    content {
      fqs = as.value
    }
  }
  attr_rendering_metadata {
    name    = "aliasApps"
    section = ""
    visible = false
    widget  = ""
  }
  based_on_template {
    value         = var.based_on_template.value
    well_known_id = var.based_on_template.well_known_id
  }
  client_ip_checking        = var.client_ip_checking
  client_type               = var.client_type
  delegated_service_names   = var.delegated_service_names
  description               = var.description
  display_name              = var.display_name
  idcs_endpoint             = var.idcs_endpoint
  is_alias_app              = false
  is_enterprise_app         = false
  is_kerberos_realm         = false
  is_login_target           = true
  is_mobile_target          = false
  is_oauth_client           = true
  is_oauth_resource         = false
  is_saml_service_provider  = false
  is_unmanaged_app          = false
  is_web_tier_policy        = false
  login_mechanism           = var.login_mechanism
  post_logout_redirect_uris = var.post_logout_redirect_uris
  redirect_uris             = var.redirect_uris
  schemas                   = var.schemas
  secondary_audiences       = var.secondary_audiences
  show_in_my_apps           = var.show_in_my_apps
  trust_scope               = var.trust_scope

}
/*
resource oci_identity_domains_grant grantidcsadmin {
  
  app {
    value = "IDCSAppId"
  }
  #app_entitlement_collection = <<Optional value not found in discovery>>
  #attribute_sets = <<Optional value not found in discovery>>
  #attributes = <<Optional value not found in discovery>>
  #authorization = <<Optional value not found in discovery>>
  entitlement {
    attribute_name  = "appRoles"
    attribute_value = "fb9dd36a22d7453abb666c0e36e124db"
  }
  grant_mechanism = "ADMINISTRATOR_TO_APP"
  #granted_attribute_values_json = <<Optional value not found in discovery>>
  grantee {
    type  = "App"
    #value = "9f715cceacba41548046cf14f0aade2e"
    value = oci_identity_domains_app.this.id
  }
  idcs_endpoint = "https://idcs-2b14051046724572b65240c1b2666907.identity.oraclecloud.com:443"
  #ocid          = "ocid1.domaingrant.oc1.iad.amaaaaaasbmnnnqadhugjvo5ptbbqlys43kl7b5bprx53hdb7vjg3sjhbrxa"
  #resource_type_schema_version = <<Optional value not found in discovery>>
  schemas = [
    "urn:ietf:params:scim:schemas:oracle:idcs:Grant",
  ]
}
*/


### service user

resource "oci_identity_domains_user" "this" {
  force_delete  = true
  idcs_endpoint = var.idcs_endpoint
  active        = var.user_active
  display_name  = var.user_display_name
  user_name     = var.user_name
  schemas = var.user_schemas
  urnietfparamsscimschemasoracleidcsextensionuser_user {
    service_user = true
  }
}

### prop trust

resource "oci_identity_domains_identity_propagation_trust" "this" {
  idcs_endpoint       = var.idcs_endpoint
  issuer              = var.issuer
  name                = var.proptrust_name
  schemas             = var.proptrust_schemas
  type                = "JWT"
  active              = var.proptrust_active
  allow_impersonation = var.allow_impersonation
  attribute_sets      = ["all"]
  attributes          = var.attributes
  description         = var.proptrust_description
  impersonation_service_users {
        rule = "actor eq ${var.actor}"
        value = oci_identity_domains_user.this.id 
  }
  oauth_clients                = [oci_identity_domains_app.this.name]
  public_key_endpoint          = var.public_key_endpoint
  resource_type_schema_version = var.resource_type_schema_version
  subject_claim_name           = var.subject_claim_name
  subject_mapping_attribute    = var.subject_mapping_attribute
  subject_type                 = var.subject_type
}

### group / policy

resource oci_identity_domains_group this {
  provider = oci.home
  display_name = var.group_name
  #force_delete = <<Optional value not found in discovery>>
  #idcs_endpoint = "https://idcs-2b14051046724572b65240c1b2666907.identity.oraclecloud.com:443"
  idcs_endpoint = var.idcs_endpoint
  schemas = [
    "urn:ietf:params:scim:schemas:core:2.0:Group",
    "urn:ietf:params:scim:schemas:oracle:idcs:extension:OCITags",
    "urn:ietf:params:scim:schemas:oracle:idcs:extension:group:Group",
  ]
  urnietfparamsscimschemasoracleidcsextension_oci_tags {
    freeform_tags {
      key   = "token_exchange_group"
      value = "YES"
    }
    freeform_tags {
      key   = "ocilz-terraform-module"
      value = "iam-groups/0.3.0"
    }
  }
  urnietfparamsscimschemasoracleidcsextensiondynamic_group {
    membership_type = "static"
  }
}

resource oci_identity_user_group_membership this {
  depends_on  = [oci_identity_domains_group.this, oci_identity_domains_user.this]
  provider    = oci.home
  group_id    = oci_identity_domains_group.this.ocid
  user_id     = oci_identity_domains_user.this.ocid
}

resource "oci_identity_policy" "this" {
 provider       = oci.home
 depends_on     = [oci_identity_domains_group.this]
 name           = "TokenExDemoPol"
 description    = "TokenExDemoPol"
 compartment_id = var.tenancy_ocid
 statements     = [
    "Allow group ${var.group_name} to manage virtual-network-family in compartment id ${var.compartment_ocid}",
    "Allow group ${var.group_name} to manage object-family in compartment id ${var.compartment_ocid}",
 ]
}
