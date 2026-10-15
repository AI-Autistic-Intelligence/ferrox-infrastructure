# ==============================================================================
# ⚡ Ferrox Polyglot Mesh Orchestration: Start All Services (mesh-up)
# ==============================================================================

$ErrorActionPreference = "Stop"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  🚀 Launching Ferrox Polyglot Ecosystem Mesh (6 Runtimes)" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Ensure Docker Network
$networkName = "ferrox-network"
$existingNet = docker network ls --filter name=^${networkName}$ --format "{{.Name}}"
if (-not $existingNet) {
    Write-Host "🌐 Creating Docker Network: $networkName..." -ForegroundColor Yellow
    docker network create $networkName
}

# 2. Start Mesh with Docker Compose
Write-Host "📦 Starting Central API Gateway, Observability Stack, and Microservices..." -ForegroundColor Green
docker compose -f docker-compose.mesh.yml up -d --remove-orphans

# 3. Print Gateway & Service URLs
Write-Host ""
Write-Host "✅ Ferrox Ecosystem Mesh is UP & HEALTHY!" -ForegroundColor Green
Write-Host "----------------------------------------------------------" -ForegroundColor Gray
Write-Host "🌐 Central API Gateway:      http://localhost:80" -ForegroundColor White
Write-Host "   - Traefik Admin Web UI:   http://localhost:8088" -ForegroundColor White
Write-Host "   - Rust Backend:           http://localhost:80/api/v1/rust/*" -ForegroundColor White
Write-Host "   - Java 21 Loom Showcase:  http://localhost:80/api/v1/java/* (or :8082)" -ForegroundColor White
Write-Host "   - PHP FrankenPHP E-Shop:  http://localhost:80/api/v1/php/* (or :8000)" -ForegroundColor White
Write-Host "   - Python Polars Platform: http://localhost:80/api/v1/py/* (or :8001)" -ForegroundColor White
Write-Host "   - Node Fastify Showcase:  http://localhost:80/api/v1/node/* (or :3000)" -ForegroundColor White
Write-Host "   - NestJS Task Service:    http://localhost:80/api/v1/nest/* (or :3002)" -ForegroundColor White
Write-Host "   - Ferrox Front Dashboard: http://localhost:4000 (or http://localhost:80)" -ForegroundColor White
Write-Host "----------------------------------------------------------" -ForegroundColor Gray
Write-Host "📊 Observability & Telemetry:" -ForegroundColor Magenta
Write-Host "   - Prometheus:             http://localhost:9090" -ForegroundColor White
Write-Host "   - Grafana (Overview):     http://localhost:3001 (admin/admin)" -ForegroundColor White
Write-Host "   - OTel Collector:         http://localhost:4318 (HTTP) / :4317 (gRPC)" -ForegroundColor White
Write-Host "==========================================================" -ForegroundColor Cyan
