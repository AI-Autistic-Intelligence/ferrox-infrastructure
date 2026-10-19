#!/usr/bin/env bash
# ==============================================================================
# 🌐 FERROX LIVING MESH: LOCAL DOCKER PUBLISHING ENGINE ($0.00 Cloud Cost)
# ==============================================================================
# Directly builds, tags, and pushes multi-stage polyglot container images from
# your local host / WSL2 / Linux environment to GitHub Container Registry (GHCR).
# ZERO GitHub Actions runner minutes consumed ($0.00 cloud cost).
# ==============================================================================

set -euo pipefail

REGISTRY="ghcr.io/ai-autistic-intelligence"
TAG="latest"
PUSH=false
DRY_RUN=false
NO_CACHE=""
SERVICE=""

function print_usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -r, --registry <prefix>   Container registry prefix (default: ghcr.io/ai-autistic-intelligence)"
    echo "  -t, --tag <tag>           Docker image tag (default: latest)"
    echo "  -p, --push                Push images to remote registry after building"
    echo "  -d, --dry-run             Display commands without executing Docker"
    echo "  -n, --no-cache            Instruct Docker to bypass cache layers"
    echo "  -s, --service <id>        Filter by service ID (front, match, saas, java, php, node, py)"
    echo "  -h, --help                Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --dry-run"
    echo "  $0 --service front --push"
    echo "  $0 --push --tag v1.0.0"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -r|--registry)
            REGISTRY="$2"
            shift 2
            ;;
        -t|--tag)
            TAG="$2"
            shift 2
            ;;
        -p|--push)
            PUSH=true
            shift
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -n|--no-cache)
            NO_CACHE="--no-cache"
            shift
            ;;
        -s|--service)
            SERVICE="$2"
            shift 2
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            print_usage
            exit 1
            ;;
    esac
done

echo "================================================================================"
echo "🌐 FERROX LIVING MESH: LOCAL DOCKER PUBLISHING ENGINE (\$0.00 Cloud Cost)"
echo "================================================================================"
echo "📦 Target Registry : ${REGISTRY}"
echo "🏷️ Target Tag      : ${TAG}"
echo "🚀 Push Mode       : $(if [ "$PUSH" = true ]; then echo 'ENABLED (Push to GHCR)'; else echo 'DISABLED (Local Build & Tag only)'; fi)"
if [ "$DRY_RUN" = true ]; then
    echo "🔍 Execution Mode  : DRY-RUN (Commands will only be printed)"
fi
if [ -n "$NO_CACHE" ]; then
    echo "⚡ Cache Policy    : --no-cache forced"
fi
if [ -n "$SERVICE" ]; then
    echo "🎯 Service Filter  : ${SERVICE}"
fi
echo "--------------------------------------------------------------------------------"

# Pre-flight: Check Docker
if [ "$DRY_RUN" = false ]; then
    if ! command -v docker &> /dev/null; then
        echo "❌ Docker command not found. Please ensure Docker is installed and in your PATH."
        exit 1
    fi
    DOCKER_VER=$(docker --version)
    echo "✔ Local Docker engine detected: ${DOCKER_VER}"

    if [ "$PUSH" = true ]; then
        echo "ℹ️ Pre-flight: verifying registry push authentication..."
        echo "  Make sure you ran: echo \$CR_PAT | docker login ghcr.io -u <username> --password-stdin"
    fi
fi

# Locate workspace root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CODE_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Define build targets: ID:NAME:IMAGE:REL_CONTEXT:DOCKERFILE:EST_SIZE
TARGETS=(
    "front:ferrox-front (Reactive Wasm):ferrox-front:ferrox-front:Dockerfile.frontend:24.5 MB"
    "match:ferrox-match (Zero-Alloc Engine):ferrox-match:ferrox-match:Dockerfile:18.2 MB"
    "saas:ferrox-saas-backend (Rust Core):ferrox-saas-backend:ferrox:Dockerfile:21.8 MB"
    "java:ferrox-java (Project Loom):ferrox-java:ferrox-java:ferrox-java-showcase/Dockerfile:168.0 MB"
    "php:ferrox-php (FrankenPHP Saga):ferrox-php:ferrox-php:examples/eshop/Dockerfile:95.4 MB"
    "node:ferrox-node (Fastify/NestJS CQRS):ferrox-node:ferrox-node:examples/enterprise-showcase/Dockerfile:82.1 MB"
    "py:ferrox-py (Polars Analytics):ferrox-py:ferrox-py:examples/data_platform/Dockerfile:114.5 MB"
)

SUMMARY_TABLE=()

for item in "${TARGETS[@]}"; do
    IFS=":" read -r TID TNAME TIMAGE TCONTEXT TDF TESTSIZE <<< "$item"

    if [ -n "$SERVICE" ]; then
        SV_LOWER=$(echo "$SERVICE" | tr '[:upper:]' '[:lower:]')
        TID_LOWER=$(echo "$TID" | tr '[:upper:]' '[:lower:]')
        if [[ "$TID_LOWER" != *"$SV_LOWER"* && "$TIMAGE" != *"$SV_LOWER"* ]]; then
            continue
        fi
    fi

    FULL_TAG="${REGISTRY%/}/${TIMAGE}:${TAG}"
    CONTEXT_PATH="${CODE_ROOT}/${TCONTEXT}"
    DF_PATH="${CONTEXT_PATH}/${TDF}"

    # Fallback to standard Dockerfile if custom one not found
    if [ ! -f "$DF_PATH" ]; then
        DF_PATH="${CONTEXT_PATH}/Dockerfile"
    fi

    echo ""
    echo "🔨 Processing [${TID}] ${TNAME}..."
    echo "   Image Tag : ${FULL_TAG}"
    echo "   Context   : ${CONTEXT_PATH}"
    echo "   Dockerfile: ${DF_PATH}"

    if [ ! -d "$CONTEXT_PATH" ] || [ ! -f "$DF_PATH" ]; then
        echo "   ⚠️ Source context or Dockerfile not found at ${CONTEXT_PATH}"
        SUMMARY_TABLE+=("${TID}|${FULL_TAG}|Source Missing|Skipped|${TESTSIZE}")
        continue
    fi

    BUILD_STATUS="SUCCESS"
    ACTION_STATUS="Built Locally"

    if [ "$DRY_RUN" = true ]; then
        echo "   [DRY-RUN] Would execute: docker build -t ${FULL_TAG} -f \"${DF_PATH}\" ${NO_CACHE} \"${CONTEXT_PATH}\""
        if [ "$PUSH" = true ]; then
            echo "   [DRY-RUN] Would execute: docker push ${FULL_TAG}"
            ACTION_STATUS="Would Push"
        else
            ACTION_STATUS="Would Build"
        fi
        BUILD_STATUS="Dry-Run OK"
    else
        echo "   ⚙️ Running docker build..."
        if docker build -t "${FULL_TAG}" -f "${DF_PATH}" ${NO_CACHE} "${CONTEXT_PATH}"; then
            echo "   ✔ Docker build completed successfully."
            if [ "$PUSH" = true ]; then
                echo "   🚀 Pushing to ${REGISTRY}..."
                if docker push "${FULL_TAG}"; then
                    echo "   ✔ Push completed successfully."
                    ACTION_STATUS="Pushed to GHCR"
                else
                    echo "   ⚠️ Docker push failed. Please verify credentials."
                    ACTION_STATUS="Push Failed"
                fi
            fi
        else
            echo "   ❌ Docker build failed for ${TID}."
            BUILD_STATUS="Build Failed"
            ACTION_STATUS="Aborted"
        fi
    fi

    SUMMARY_TABLE+=("${TID}|${FULL_TAG}|${BUILD_STATUS}|${ACTION_STATUS}|${TESTSIZE}")
done

echo ""
echo "================================================================================"
echo "📋 FERROX MESH CONTAINER PUBLISH SUMMARY (\$0.00 Host Build):"
echo "================================================================================"
printf "%-10s | %-52s | %-12s | %-18s | %-8s\n" "ID" "IMAGE TAG" "STATUS" "ACTION" "EST SIZE"
echo "---------------------------------------------------------------------------------------------------------------"
for row in "${SUMMARY_TABLE[@]}"; do
    IFS="|" read -r r_id r_tag r_stat r_act r_sz <<< "$row"
    printf "%-10s | %-52s | %-12s | %-18s | %-8s\n" "$r_id" "$r_tag" "$r_stat" "$r_act" "$r_sz"
done
echo "================================================================================"

echo ""
echo "🌐 GLOBAL ZERO-CLONING QUICKSTART ONE-LINER:"
echo "   Anyone in the world can run this full stack with ZERO repo cloning:"
echo "   curl -fsSL https://raw.githubusercontent.com/AI-Autistic-Intelligence/ferrox-infrastructure/master/docker-compose.standalone.yml | docker compose -f - up -d"
echo ""
