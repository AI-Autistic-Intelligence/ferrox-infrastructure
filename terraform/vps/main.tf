terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

variable "vps_ip" {
  description = "IP address of the bare-metal VPS"
  type        = string
}

variable "ssh_user" {
  description = "SSH username for the VPS"
  type        = string
  default     = "root"
}

variable "ssh_private_key_path" {
  description = "Path to SSH private key"
  type        = string
}

# This represents a bare-metal provisioning approach.
# In a real environment, you might use a provider like Hetzner/DigitalOcean to spin up the VPS first,
# but if the user provides an existing IP, we use remote-exec to bootstrap the environment.
resource "null_resource" "ferrox_vps_bootstrap" {
  triggers = {
    always_run = timestamp()
  }

  connection {
    type        = "ssh"
    user        = var.ssh_user
    private_key = file(var.ssh_private_key_path)
    host        = var.vps_ip
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Bootstrapping Ferrox Ecosystem on VPS...'",
      # 1. Install Docker & Docker Compose
      "apt-get update && apt-get install -y docker.io docker-compose",
      "systemctl enable docker",
      "systemctl start docker",
      
      # 2. Setup Directories
      "mkdir -p /opt/ferrox/data/postgres",
      "mkdir -p /opt/ferrox/data/redis",
      
      # 3. Create Docker Compose file for Ferrox Ecosystem (Polyglot Hub)
      "cat << 'EOF' > /opt/ferrox/docker-compose.yml",
      "version: '3.8'",
      "services:",
      "  # --- DATA STORAGE LAYER ---",
      "  ferrox-postgres:",
      "    image: postgres:15-alpine",
      "    environment:",
      "      POSTGRES_USER: ferrox",
      "      POSTGRES_PASSWORD: ${var.db_password}",
      "      POSTGRES_DB: ferrox",
      "    volumes:",
      "      - ./data/postgres:/var/lib/postgresql/data",
      "    ports:",
      "      - '127.0.0.1:5432:5432'",
      "  ferrox-redis:",
      "    image: redis:7-alpine",
      "    volumes:",
      "      - ./data/redis:/data",
      "    ports:",
      "      - '127.0.0.1:6379:6379'",
      "",
      "  # --- MICROSERVICES LAYER ---",
      "  # 1. PHP Core (API Gateway & Security)",
      "  ferrox-php-gateway:",
      "    image: ferrox/php-gateway:latest",
      "    ports:",
      "      - '80:80'",
      "    depends_on:",
      "      - ferrox-postgres",
      "",
      "  # 2. Python Data Platform (ETL & Quant Analytics)",
      "  ferrox-py-dataplatform:",
      "    image: ferrox/py-dataplatform:latest",
      "    ports:",
      "      - '8000:8000'",
      "    depends_on:",
      "      - ferrox-redis",
      "",
      "  # 3. Node.js (Real-time Broadcast & Graph APIs)",
      "  ferrox-node-realtime:",
      "    image: ferrox/node-realtime:latest",
      "    ports:",
      "      - '3000:3000'",
      "    depends_on:",
      "      - ferrox-redis",
      "",
      "  # 4. Java (Heavy lifting / Event Sourcing)",
      "  ferrox-java-processor:",
      "    image: ferrox/java-processor:latest",
      "    ports:",
      "      - '8080:8080'",
      "    depends_on:",
      "      - ferrox-postgres",
      "EOF",
      
      # 4. Start the cluster
      "cd /opt/ferrox && docker-compose up -d"
    ]
  }
}

variable "db_password" {
  type = string
}
