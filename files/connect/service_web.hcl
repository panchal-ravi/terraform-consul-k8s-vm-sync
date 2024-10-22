service {
  id   = "web"
  name = "web"
  tags = ["primary"]
  port = 9090
  checks = [
    {
      id       = "http_health_check"
      name     = "/health"
      http     = "http://localhost:9090/health"
      interval = "10s"
      timeout  = "2s"
    }
  ]

  connect {
    sidecar_service {
      proxy {
        expose {
          checks = true
        }
        upstreams = [
          {
            destination_name = "api"
            local_bind_port = 9091
          }
        ]
      }
    }
  }
}
