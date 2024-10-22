service {
  id   = "api"
  name = "api"
  tags = ["primary"]
  port = 8080
  checks = [
    {
      id       = "http_health_check"
      name     = "/health"
      http     = "http://localhost:8080/health"
      interval = "10s"
      timeout  = "2s"
    }
  ]
}
