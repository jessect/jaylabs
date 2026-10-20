# No mock_provider block: terraform test uses the REAL google provider.
run "bucket_name" {
  command = plan

  assert {
    condition     = google_storage_bucket.this.name == "jaylabs-lab003-naive-bucket"
    error_message = "Unexpected bucket name."
  }
}
