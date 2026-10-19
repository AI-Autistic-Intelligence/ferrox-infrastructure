<#
.SYNOPSIS
    Ferrox Mesh Container Engine: Direct Host Docker Publishing ($0.00 Cloud Cost).

.DESCRIPTION
    Builds, tags, and pushes all polyglot microservice Docker images directly from the local
    host machine to GitHub Container Registry (GHCR) or a custom container registry.
    Requires NO GitHub Actions runner minutes ($0.00 cloud cost).

.PARAMETER Registry
    The container registry prefix (default: 'ghcr.io/ai-autistic-intelligence').

.PARAMETER Tag
    The Docker image tag (default: 'latest').

.PARAMETER Push
    If specified, pushes the built images to the remote registry.

.PARAMETER DryRun
    If specified, displays commands without invoking Docker.

.PARAMETER NoCache
    If specified, instructs Docker to bypass cached layers.

.PARAMETER Service
    Filter by service name or ID (front, match, saas, java, php, node, py).

.EXAMPLE
    .\publish-mesh-images.ps1 -DryRun
    .\publish-mesh-images.ps1 -Service front -Push
    .\publish-mesh-images.ps1 -Push -Tag v1.0.0
#>

[CmdletBinding()]
param(
    [string]$Registry = "ghcr.io/ai-autistic-intelligence",
    [string]$Tag = "latest",
    [switch]$Push,
    [switch]$DryRun,
    [switch]$NoCache,
    [string]$Service = ""
)

$ErrorActionPreference = "Continue"

Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "🌐 FERROX LIVING MESH: LOCAL DOCKER PUBLISHING ENGINE ($0.00 Cloud Cost)" -ForegroundColor Cyan
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "📦 Target Registry : $Registry" -ForegroundColor White
Write-Host "🏷️ Target Tag      : $Tag" -ForegroundColor White
Write-Host "🚀 Push Mode       : $(if ($Push) { 'ENABLED (Push to GHCR)' } else { 'DISABLED (Local Build & Tag only)' })" -ForegroundColor Yellow
if ($DryRun) {
    Write-Host "🔍 Execution Mode  : DRY-RUN (Commands will only be printed)" -ForegroundColor Magenta
}
if ($NoCache) {
    Write-Host "⚡ Cache Policy    : --no-cache forced" -ForegroundColor DarkYellow
}
if ($Service) {
    Write-Host "🎯 Service Filter  : $Service" -ForegroundColor Green
}
Write-Host "--------------------------------------------------------------------------------" -ForegroundColor Gray

# Pre-flight: Check Docker
if (-not $DryRun) {
    try {
        $dockerVer = docker --version
        Write-Host "✔ Local Docker engine detected: $dockerVer" -ForegroundColor Green
    }
    catch {
        Write-Host "⚠️ Docker command failed or daemon not running. Please start Docker Desktop or dockerd." -ForegroundColor Red
        if (-not $DryRun) { exit 1 }
    }

    if ($Push) {
        Write-Host "ℹ️ Pre-flight: verifying registry push authentication..." -ForegroundColor DarkGray
        Write-Host "  Make sure you ran: echo `$CR_PAT | docker login ghcr.io -u <user> --password-stdin" -ForegroundColor DarkGray
    }
}

# Resolve Workspace Root (sibling repositories)
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Candidates = @(
    (Resolve-Path "$ScriptDir\..\.." -ErrorAction SilentlyContinue),
    (Resolve-Path "$ScriptDir\.." -ErrorAction SilentlyContinue),
    (Get-Location).Path
)

$CodeRoot = $null
foreach ($c in $Candidates) {
    if ($c -and (Test-Path "$c\ferrox") -and (Test-Path "$c\ferrox-front")) {
        $CodeRoot = $c.Path
        break
    }
}

if (-not $CodeRoot) {
    # Fallback to standard Desktop\code location
    $DefaultCode = "c:\Users\nn\Desktop\code"
    if (Test-Path $DefaultCode) {
        $CodeRoot = $DefaultCode
    } else {
        $CodeRoot = (Resolve-Path "$ScriptDir\..\..").Path
    }
}

Write-Host "📂 Workspace Code Root: $CodeRoot" -ForegroundColor DarkGray

# Define targets
$Targets = @(
    @{
        Id = "front"
        Name = "ferrox-front (Reactive Wasm Dashboard)"
        Image = "ferrox-front"
        Context = "$CodeRoot\ferrox-front"
        Dockerfiles = @("$CodeRoot\ferrox-front\Dockerfile", "$CodeRoot\ferrox-front\Dockerfile.frontend")
        EstSize = "24.5 MB"
    },
    @{
        Id = "match"
        Name = "ferrox-match (Zero-Alloc Order Engine)"
        Image = "ferrox-match"
        Context = "$CodeRoot\ferrox-match"
        Dockerfiles = @("$CodeRoot\ferrox-match\Dockerfile")
        EstSize = "18.2 MB"
    },
    @{
        Id = "saas"
        Name = "ferrox-saas-backend (Rust Core Engine)"
        Image = "ferrox-saas-backend"
        Context = "$CodeRoot\ferrox"
        Dockerfiles = @("$CodeRoot\ferrox\Dockerfile")
        EstSize = "21.8 MB"
    },
    @{
        Id = "java"
        Name = "ferrox-java (Project Loom Ledger)"
        Image = "ferrox-java"
        Context = "$CodeRoot\ferrox-java"
        Dockerfiles = @("$CodeRoot\ferrox-java\ferrox-java-showcase\Dockerfile", "$CodeRoot\ferrox-java\Dockerfile")
        EstSize = "168.0 MB"
    },
    @{
        Id = "php"
        Name = "ferrox-php (FrankenPHP Saga Coordinator)"
        Image = "ferrox-php"
        Context = "$CodeRoot\ferrox-php"
        Dockerfiles = @("$CodeRoot\ferrox-php\examples\eshop\Dockerfile", "$CodeRoot\ferrox-php\Dockerfile")
        EstSize = "95.4 MB"
    },
    @{
        Id = "node"
        Name = "ferrox-node (Fastify / NestJS Audit)"
        Image = "ferrox-node"
        Context = "$CodeRoot\ferrox-node"
        Dockerfiles = @("$CodeRoot\ferrox-node\examples\enterprise-showcase\Dockerfile", "$CodeRoot\ferrox-node\Dockerfile")
        EstSize = "82.1 MB"
    },
    @{
        Id = "py"
        Name = "ferrox-py (Polars Analytics Worker)"
        Image = "ferrox-py"
        Context = "$CodeRoot\ferrox-py"
        Dockerfiles = @("$CodeRoot\ferrox-py\examples\data_platform\Dockerfile", "$CodeRoot\ferrox-py\Dockerfile")
        EstSize = "114.5 MB"
    }
)

$SummaryResults = @()

foreach ($t in $Targets) {
    if ($Service) {
        $filter = $Service.ToLower()
        if ($t.Id -ne $filter -and -not $t.Image.ToLower().Contains($filter)) {
            continue
        }
    }

    $fullTag = "$($Registry.TrimEnd('/'))/$($t.Image):$Tag"
    Write-Host "`n🔨 Processing [$($t.Id)] $($t.Name)..." -ForegroundColor Cyan
    Write-Host "   Full Image Tag : $fullTag" -ForegroundColor White

    # Locate valid Dockerfile
    $chosenDockerfile = $null
    foreach ($df in $t.Dockerfiles) {
        if (Test-Path $df) {
            $chosenDockerfile = $df
            break
        }
    }

    if (-not $chosenDockerfile -or -not (Test-Path $t.Context)) {
        Write-Host "   ⚠️ Could not locate Dockerfile or Context at: $($t.Context)" -ForegroundColor Red
        $SummaryResults += [PSCustomObject]@{
            Id = $t.Id
            Image = $fullTag
            Status = "Not Found"
            Action = "Skipped"
            Time = "0s"
        }
        continue
    }

    Write-Host "   Context Path   : $($t.Context)" -ForegroundColor Gray
    Write-Host "   Dockerfile     : $chosenDockerfile" -ForegroundColor Gray

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $buildStatus = "SUCCESS"
    $actionStatus = if ($Push) { "Pushed" } else { "Built Locally" }

    if ($DryRun) {
        $cmdBuild = "docker build -t $fullTag -f `"$chosenDockerfile`""
        if ($NoCache) { $cmdBuild += " --no-cache" }
        $cmdBuild += " `"$($t.Context)`""
        Write-Host "   [DRY-RUN] Would execute: $cmdBuild" -ForegroundColor Magenta

        if ($Push) {
            Write-Host "   [DRY-RUN] Would execute: docker push $fullTag" -ForegroundColor Magenta
            $actionStatus = "Would Push"
        } else {
            $actionStatus = "Would Build"
        }
        $buildStatus = "Dry-Run OK"
    } else {
        Write-Host "   ⚙️ Running docker build..." -ForegroundColor Yellow
        $buildArgs = @("build", "-t", $fullTag, "-f", $chosenDockerfile)
        if ($NoCache) { $buildArgs += "--no-cache" }
        $buildArgs += $t.Context

        & docker @buildArgs
        if ($LASTEXITCODE -ne 0) {
            Write-Host "   ❌ Docker build failed for $($t.Id) (Exit code $LASTEXITCODE)" -ForegroundColor Red
            $buildStatus = "Build Failed"
            $actionStatus = "Aborted"
        } else {
            Write-Host "   ✔ Docker build completed successfully." -ForegroundColor Green
            if ($Push) {
                Write-Host "   🚀 Pushing to $Registry..." -ForegroundColor Yellow
                & docker push $fullTag
                if ($LASTEXITCODE -ne 0) {
                    Write-Host "   ⚠️ Push failed (Exit code $LASTEXITCODE). Check your credentials." -ForegroundColor Red
                    $actionStatus = "Push Failed"
                } else {
                    Write-Host "   ✔ Push completed successfully." -ForegroundColor Green
                    $actionStatus = "Pushed to Registry"
                }
            }
        }
    }

    $sw.Stop()
    $elapsed = "$([math]::Round($sw.Elapsed.TotalSeconds, 1))s"

    $SummaryResults += [PSCustomObject]@{
        Id = $t.Id
        Image = $fullTag
        Status = $buildStatus
        Action = $actionStatus
        Time = $elapsed
    }
}

Write-Host "`n================================================================================" -ForegroundColor Cyan
Write-Host "📋 FERROX MESH CONTAINER PUBLISH SUMMARY ($0.00 Host Build):" -ForegroundColor Cyan
Write-Host "================================================================================" -ForegroundColor Cyan

$SummaryResults | Format-Table -AutoSize

Write-Host "`n🌐 GLOBAL ZERO-CLONING QUICKSTART ONE-LINER:" -ForegroundColor Green
Write-Host "   curl -fsSL https://raw.githubusercontent.com/AI-Autistic-Intelligence/ferrox-infrastructure/master/docker-compose.standalone.yml | docker compose -f - up -d`n" -ForegroundColor Yellow
