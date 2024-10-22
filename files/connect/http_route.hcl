Kind = "http-route"
Name = "my-http-route"

// Rules define how requests will be routed
Rules = [
  // Send all requests to web service
  {
    Matches = [
      {
        Path = {
          Match = "prefix"
          Value = "/"
        }
      }
    ]
    Services = [
      {
        Name = "web"
      }
    ]
  }
]

Parents = [
  {
    Kind = "api-gateway"
    Name = "my-api-gateway"
    SectionName = "my-http-listener"
  }
]
