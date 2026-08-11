path "sys/policies/acl/meta-harness-credential-ingest" {
  capabilities = ["create", "update", "read"]
}

path "sys/policies/acl/meta-harness-worker" {
  capabilities = ["create", "update", "read"]
}

path "auth/kubernetes/role/meta-harness-credential-ingest" {
  capabilities = ["create", "update", "read"]
}

path "auth/kubernetes/role/meta-harness-worker" {
  capabilities = ["create", "update", "read"]
}
