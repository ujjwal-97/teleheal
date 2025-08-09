#!/bin/bash

# Smart CI/CD Script for Teleheal Project - GitHub Actions Optimized
# This script detects changes in different modules and triggers appropriate CI/CD workflows

set -e

# GitHub Actions environment detection
if [[ "${GITHUB_ACTIONS}" == "true" ]]; then
    # Use GitHub Actions logging
    print_info() { echo "::notice::$1"; }
    print_success() { echo "::notice::✅ $1"; }
    print_warning() { echo "::warning::$1"; }
    print_error() { echo "::error::$1"; }
    print_debug() { echo "::debug::$1"; }
else
    # Colors for local output
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m' # No Color
    
    print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
    print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
    print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
    print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
    print_debug() { echo -e "${BLUE}[DEBUG]${NC} $1"; }
fi

# Configuration
BACKEND_DIR="teleheal-backend"
FRONTEND_DIR="teleheal-ui"
WORKFLOWS_DIR=".github/workflows"
DEFAULT_BRANCH="master"

# GitHub Actions output functions
set_output() {
    if [[ "${GITHUB_ACTIONS}" == "true" ]]; then
        echo "$1=$2" >> $GITHUB_OUTPUT
    else
        echo "OUTPUT: $1=$2"
    fi
}

add_summary() {
    if [[ "${GITHUB_ACTIONS}" == "true" ]]; then
        echo "$1" >> $GITHUB_STEP_SUMMARY
    else
        echo "SUMMARY: $1"
    fi
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help          Show this help message"
    echo "  -b, --base-ref REF  Base reference for diff (default: HEAD~1)"
    echo "  -t, --target-ref REF Target reference for diff (default: HEAD)"
    echo "  --backend-only      Force run backend CI/CD only"
    echo "  --frontend-only     Force run frontend CI/CD only"
    echo "  --skip-docker       Skip Docker image building"
    echo "  --skip-integration  Skip integration tests"
    echo "  --dry-run           Show what would be executed without running"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Detect changes and run appropriate workflows"
    echo "  $0 --base-ref origin/master          # Compare with origin/master"
    echo "  $0 --backend-only                    # Force run backend workflow"
    echo "  $0 --dry-run                         # Show what would be executed"
}

# Function to check if we're in a git repository
check_git_repo() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        print_error "Not in a git repository!"
        exit 1
    fi
}

# Function to get changed files between commits
get_changed_files() {
    local base_ref="${1:-HEAD~1}"
    local head_ref="${2:-HEAD}"
    
    print_info "Checking changes between $base_ref and $head_ref"
    git diff --name-only "$base_ref" "$head_ref" 2>/dev/null || {
        print_warning "Could not get diff. Using staged and unstaged changes."
        git diff --name-only HEAD
        git diff --name-only --cached
    }
}

# Function to detect module changes
detect_changes() {
    local changed_files="$1"
    local backend_changed=false
    local frontend_changed=false
    local workflows_changed=false
    local docker_changed=false
    
    if [[ -z "$changed_files" ]]; then
        print_warning "No changes detected"
        return 0
    fi
    
    while IFS= read -r file; do
        if [[ -n "$file" ]]; then
            case "$file" in
                $BACKEND_DIR/*)
                    backend_changed=true
                    print_info "Backend change detected: $file"
                    ;;
                $FRONTEND_DIR/*)
                    frontend_changed=true
                    print_info "Frontend change detected: $file"
                    ;;
                $WORKFLOWS_DIR/*)
                    workflows_changed=true
                    print_info "Workflow change detected: $file"
                    ;;
                docker-compose.yaml|*/Dockerfile)
                    docker_changed=true
                    print_info "Docker configuration change detected: $file"
                    ;;
                README.md|*.md)
                    print_info "Documentation change detected: $file"
                    ;;
            esac
        fi
    done <<< "$changed_files"
    
    echo "$backend_changed,$frontend_changed,$workflows_changed,$docker_changed"
}

# Function to run backend CI/CD
run_backend_ci_cd() {
    local dry_run="$1"
    
    print_info "Running Backend CI/CD..."
    
    if [[ "$dry_run" == "true" ]]; then
        print_info "[DRY RUN] Would run backend CI/CD"
        return 0
    fi
    
    # Check if backend directory exists
    if [[ ! -d "$BACKEND_DIR" ]]; then
        print_error "Backend directory '$BACKEND_DIR' not found!"
        return 1
    fi
    
    cd "$BACKEND_DIR"
    
    # Make gradlew executable
    if [[ -f "gradlew" ]]; then
        chmod +x gradlew
        print_info "Made gradlew executable"
    else
        print_error "gradlew not found in backend directory!"
        cd ..
        return 1
    fi
    
    # Run tests and build
    print_info "Running backend tests and build..."
    if ./gradlew clean build; then
        print_success "Backend build completed successfully"
    else
        print_error "Backend build failed!"
        cd ..
        return 1
    fi
    
    cd ..
    return 0
}

# Function to run frontend CI/CD
run_frontend_ci_cd() {
    local dry_run="$1"
    
    print_info "Running Frontend CI/CD..."
    
    if [[ "$dry_run" == "true" ]]; then
        print_info "[DRY RUN] Would run frontend CI/CD"
        return 0
    fi
    
    # Check if frontend directory exists
    if [[ ! -d "$FRONTEND_DIR" ]]; then
        print_error "Frontend directory '$FRONTEND_DIR' not found!"
        return 1
    fi
    
    cd "$FRONTEND_DIR"
    
    # Check if package.json exists
    if [[ ! -f "package.json" ]]; then
        print_error "package.json not found in frontend directory!"
        cd ..
        return 1
    fi
    
    # Install dependencies
    print_info "Installing frontend dependencies..."
    if npm ci; then
        print_success "Frontend dependencies installed"
    else
        print_error "Failed to install frontend dependencies!"
        cd ..
        return 1
    fi
    
    # Run linting (optional, continue on failure)
    print_info "Running frontend linting..."
    npm run lint || print_warning "Linting failed, continuing..."
    
    # Run tests
    print_info "Running frontend tests..."
    if npm run test -- --watchAll=false --coverage; then
        print_success "Frontend tests passed"
    else
        print_warning "Frontend tests failed, continuing with build..."
    fi
    
    # Build application
    print_info "Building frontend application..."
    if npm run build; then
        print_success "Frontend build completed successfully"
    else
        print_error "Frontend build failed!"
        cd ..
        return 1
    fi
    
    cd ..
    return 0
}

# Function to build Docker images
build_docker_images() {
    local backend_changed="$1"
    local frontend_changed="$2"
    local dry_run="$3"
    
    print_info "Building Docker images..."
    
    if [[ "$dry_run" == "true" ]]; then
        [[ "$backend_changed" == "true" ]] && print_info "[DRY RUN] Would build backend Docker image"
        [[ "$frontend_changed" == "true" ]] && print_info "[DRY RUN] Would build frontend Docker image"
        return 0
    fi
    
    if [[ "$backend_changed" == "true" ]]; then
        print_info "Building backend Docker image..."
        if docker build -t teleheal-backend:latest "$BACKEND_DIR"; then
            print_success "Backend Docker image built successfully"
        else
            print_error "Failed to build backend Docker image!"
            return 1
        fi
    fi
    
    if [[ "$frontend_changed" == "true" ]]; then
        print_info "Building frontend Docker image..."
        if docker build -t teleheal-frontend:latest "$FRONTEND_DIR"; then
            print_success "Frontend Docker image built successfully"
        else
            print_error "Failed to build frontend Docker image!"
            return 1
        fi
    fi
    
    return 0
}

# Function to run integration tests
run_integration_tests() {
    local dry_run="$1"
    
    print_info "Running integration tests with docker-compose..."
    
    if [[ "$dry_run" == "true" ]]; then
        print_info "[DRY RUN] Would run integration tests"
        return 0
    fi
    
    if [[ ! -f "docker-compose.yaml" ]]; then
        print_warning "docker-compose.yaml not found, skipping integration tests"
        return 0
    fi
    
    # Build and start services
    if docker-compose up -d --build; then
        print_success "Services started successfully"
        
        # Wait for services to be ready
        print_info "Waiting for services to be ready..."
        sleep 15
        
        # Test backend health
        if timeout 30 bash -c 'until curl -f http://localhost:8080/api/health 2>/dev/null; do sleep 2; done'; then
            print_success "Backend health check passed"
        else
            print_warning "Backend health check failed or timed out"
        fi
        
        # Test frontend
        if timeout 30 bash -c 'until curl -f http://localhost:9000 2>/dev/null; do sleep 2; done'; then
            print_success "Frontend health check passed"
        else
            print_warning "Frontend health check failed or timed out"
        fi
        
        # Cleanup
        print_info "Stopping services..."
        docker-compose down
        
        print_success "Integration tests completed"
    else
        print_error "Failed to start services with docker-compose!"
        return 1
    fi
    
    return 0
}

# Main function
main() {
    local base_ref="HEAD~1"
    local target_ref="HEAD"
    local backend_only=false
    local frontend_only=false
    local skip_docker=false
    local skip_integration=false
    local dry_run=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -b|--base-ref)
                base_ref="$2"
                shift 2
                ;;
            -t|--target-ref)
                target_ref="$2"
                shift 2
                ;;
            --backend-only)
                backend_only=true
                shift
                ;;
            --frontend-only)
                frontend_only=true
                shift
                ;;
            --skip-docker)
                skip_docker=true
                shift
                ;;
            --skip-integration)
                skip_integration=true
                shift
                ;;
            --dry-run)
                dry_run=true
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    print_info "Starting Smart CI/CD for Teleheal Project"
    print_info "=========================================="
    
    # Check if we're in a git repository
    check_git_repo
    
    # Detect changes or use forced options
    local backend_changed=false
    local frontend_changed=false
    local workflows_changed=false
    local docker_changed=false
    
    if [[ "$backend_only" == "true" ]]; then
        backend_changed=true
        print_info "Forced backend-only mode"
    elif [[ "$frontend_only" == "true" ]]; then
        frontend_changed=true
        print_info "Forced frontend-only mode"
    else
        # Get changed files and detect modules
        local changed_files
        changed_files=$(get_changed_files "$base_ref" "$target_ref")
        
        if [[ -n "$changed_files" ]]; then
            print_info "Changed files:"
            echo "$changed_files" | sed 's/^/  /'
            
            local changes
            changes=$(detect_changes "$changed_files")
            IFS=',' read -r backend_changed frontend_changed workflows_changed docker_changed <<< "$changes"
        else
            print_warning "No changes detected between $base_ref and $target_ref"
            exit 0
        fi
    fi
    
    # Summary of what will be executed
    print_info ""
    print_info "Execution Plan:"
    print_info "==============="
    [[ "$backend_changed" == "true" ]] && print_info "✓ Backend CI/CD will be executed"
    [[ "$frontend_changed" == "true" ]] && print_info "✓ Frontend CI/CD will be executed"
    [[ "$skip_docker" == "false" && ("$backend_changed" == "true" || "$frontend_changed" == "true") ]] && print_info "✓ Docker images will be built"
    [[ "$skip_integration" == "false" && ("$backend_changed" == "true" || "$frontend_changed" == "true") ]] && print_info "✓ Integration tests will be run"
    
    if [[ "$backend_changed" == "false" && "$frontend_changed" == "false" ]]; then
        print_info "✓ No module changes detected, only documentation or workflow changes"
        exit 0
    fi
    
    print_info ""
    
    # Execute CI/CD workflows
    local exit_code=0
    
    if [[ "$backend_changed" == "true" ]]; then
        if ! run_backend_ci_cd "$dry_run"; then
            exit_code=1
        fi
    fi
    
    if [[ "$frontend_changed" == "true" ]]; then
        if ! run_frontend_ci_cd "$dry_run"; then
            exit_code=1
        fi
    fi
    
    # Build Docker images if requested
    if [[ "$skip_docker" == "false" && ("$backend_changed" == "true" || "$frontend_changed" == "true") ]]; then
        if ! build_docker_images "$backend_changed" "$frontend_changed" "$dry_run"; then
            exit_code=1
        fi
    fi
    
    # Run integration tests if requested
    if [[ "$skip_integration" == "false" && ("$backend_changed" == "true" || "$frontend_changed" == "true") ]]; then
        if ! run_integration_tests "$dry_run"; then
            exit_code=1
        fi
    fi
    
    # Final summary
    print_info ""
    if [[ $exit_code -eq 0 ]]; then
        print_success "Smart CI/CD completed successfully!"
    else
        print_error "Smart CI/CD completed with errors!"
    fi
    
    exit $exit_code
}

# Run main function with all arguments
main "$@"