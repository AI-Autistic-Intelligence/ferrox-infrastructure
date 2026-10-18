# ==============================================================================
# ⚡ Ferrox Polyglot Living Mesh: Local Load Stress Test Runner ($0.00 Cloud Cost)
# ==============================================================================

$ErrorActionPreference = "Stop"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  🚀 Launching Ferrox Mesh 10,000 Tx End-to-End Stress Test" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

$scriptPath = Join-Path $PSScriptRoot "mesh_load_test.py"
python $scriptPath
