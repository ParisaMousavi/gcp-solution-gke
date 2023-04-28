output "cluster_version" {
  value = data.google_container_engine_versions.this.release_channel_default_version["STABLE"]
}

data "google_container_engine_versions" "this" {
  version_prefix = "1.25."
}
