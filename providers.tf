provider "digitalocean" {
  token = var.do_token

  requests_per_second = 2
  http_retry_max      = 10
  http_retry_wait_min = 2
  http_retry_wait_max = 30
}
