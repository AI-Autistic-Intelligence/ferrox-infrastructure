# ==============================================================================
# 🛑 Ferrox Polyglot Mesh Orchestration: Stop All Services (mesh-down)
# ==============================================================================

$ErrorActionPreference = "Continue"

Write-Host "==========================================================" -ForegroundColor Yellow
Write-Host "  🛑 Stopping Ferrox Polyglot Ecosystem Mesh" -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Yellow

docker compose -f docker-compose.mesh.yml down --remove-orphans

Write-Host "✅ All mesh services and networks successfully stopped." -ForegroundColor Green
