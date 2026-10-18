terraform {
  backend "s3" {
    # GitHub Actions supplies bucket, key, and region during terraform init.
    encrypt      = true
    use_lockfile = true
  }
}
