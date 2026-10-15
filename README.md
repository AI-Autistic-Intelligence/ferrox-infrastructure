# Ferrox Infrastructure (IaC & Unified Mesh Orchestration 2.0)

![Platform](https://img.shields.io/badge/Platform-Polyglot_Mesh-blue.svg)
![Gateway](https://img.shields.io/badge/Gateway-Traefik_v3-brightgreen.svg)
![Observability](https://img.shields.io/badge/Observability-OTel_+_Prometheus_+_Grafana-orange.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

**Ferrox Infrastructure** is the centralized orchestration and Platform Engineering hub for the entire Ferrox & Yalc ecosystem. It provides the **Unified Mesh Orchestration (`docker-compose.mesh.yml`)**, Central API Gateway (Traefik v3), shared telemetry (OpenTelemetry, Prometheus, Grafana), and cloud provisioning (Terraform AWS/GCP/VPS).

---

## 🏛 Unified Polyglot Mesh Architecture

```mermaid
graph TD
    Client["Client / Browser (:80)"] --> Traefik["Central API Gateway (Traefik v3 :80)"]

    subgraph "Unified Routing Mesh (/api/v1/*)"
        Traefik -->|/api/v1/rust/*| Rust["ferrox (Rust SaaS Backend :8080)"]
        Traefik -->|/api/v1/java/*| Java["ferrox-java (Java 21 Loom :8082)"]
        Traefik -->|/api/v1/php/*| Php["ferrox-php (FrankenPHP E-Shop :8000)"]
        Traefik -->|/api/v1/py/*| Py["ferrox-py (Polars Platform :8001)"]
        Traefik -->|/api/v1/node/*| Node["ferrox-node (Fastify :3000)"]
        Traefik -->|/api/v1/nest/*| Nest["nestjs-yalc (Clean Arch :3002)"]
        Traefik -->|/* (Fallback)| Front["ferrox-front (Wasm Admin Dashboard :4000)"]
    end

    subgraph "Shared Observability Stack"
        Rust & Java & Php & Py & Node & Nest -.->|OTLP Traces & Metrics| OTel["OTel Collector (:4317/:4318)"]
        OTel --> Prom["Prometheus (:9090)"]
        Prom --> Grafana["Grafana Dashboard (:3001)"]
    end

    subgraph "Shared Persistence & Caching"
        Rust & Java & Php & Py & Node & Nest --> PG["PostgreSQL 16 (:5432)"]
        Rust & Java & Php & Py & Node & Nest --> Redis["Redis 7 (:6379)"]
    end
```

---

## ⚡ Quick Start: Mesh Orchestration

Start the entire polyglot ecosystem with one command:

```powershell
# In PowerShell:
./mesh-up.ps1

# Stop the mesh:
./mesh-down.ps1
```

Or using standard Docker Compose:

```bash
docker compose -f docker-compose.mesh.yml up -d
docker compose -f docker-compose.mesh.yml down
```

---

## 📡 Gateway Routing Table

| Gateway Route | Internal Service | Port | Description |
| :--- | :--- | :--- | :--- |
| `/api/v1/rust/*` | `ferrox-saas-backend` | 8080 | Rust High-Frequency Limit Order Book & Engine |
| `/api/v1/java/*` | `ferrox-java-showcase` | 8082 | Java 21 Loom Virtual Threads & Panama Off-Heap Cache |
| `/api/v1/php/*` | `ferrox-php-eshop` | 8000 | FrankenPHP Worker Mode & Distributed Saga Orchestration |
| `/api/v1/py/*` | `ferrox-py-platform` | 8001 | Python Polars High-Throughput Analytics & DAGs |
| `/api/v1/node/*` | `ferrox-node-showcase` | 3000 | Fastify 5 Modular Microservice |
| `/api/v1/nest/*` | `nestjs-yalc-task` | 3002 | NestJS Clean Architecture Multi-Tenant Task API |
| `/*` | `ferrox-front-dashboard` | 4000 | WebAssembly Admin Dashboard (Glassmorphic) |

---

## 📊 Observability & Telemetry Endpoints

- **Central API Gateway**: `http://localhost:80`
- **Traefik Admin Dashboard**: `http://localhost:8088`
- **Prometheus Scrape Engine**: `http://localhost:9090`
- **Grafana Pre-configured Dashboard**: `http://localhost:3001` (Credentials: `admin` / `admin`)
- **OpenTelemetry Collector**: `http://localhost:4318` (HTTP OTLP) / `localhost:4317` (gRPC OTLP)
