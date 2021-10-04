job "homework" {
    datacenters = ["dc1"]

    group "density" {
        network {
            mode = "bridge"
            port "frontend" { 
                static = 5000
            }
            port "backend" {
                static = 5001
            }
         }

        service {
            name = "frontend"
            port = "frontend"

            connect {
                sidecar_service {}
                  } 
                }
            
         

        service {
            name = "backend"
            port = "backend"

            connect {
                sidecar_service {}
            }
        }

        task "frontend" {
            driver = "docker"
            config {
                image = "geoj/density_frontend"
                ports = ["frontend"]
            }
        }
    

        task "backend" {
            driver = "docker"
            config {
                image = "geoj/density_backend"
                ports = ["backend"]
            }
        }
    }
}