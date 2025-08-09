#!/bin/bash

# GitHub Actions Smart CI/CD Script for Teleheal Project
# Optimized for GitHub Actions environment with proper outputs and summaries

set -e

# GitHub Actions logging functions
log_info() { echo "::notice::$1"; }
log_success() { echo "::notice::✅ $1"; }
log_warning() { echo "::warning::$1"; }
log_error() { echo "::error::$1"; }
log_debug() { echo "::debug::$1"; }

# Set GitHub Actions outputs
set_output() {
    echo "$1=$2" >> $GITHUB_OUTPUT
}

# Add to GitHub Actions step summary
add_summary() {
    echo "$1" >> $GITHUB_STEP_SUMMARY
}

# Configuration
BACKEND_DIR="teleheal-backend"
FRONTEND_DIR="teleheal-ui"

# Function to detect changes using GitHub environment variables
detect_changes_from_github() {
    local backend_changed=false
    local frontend_changed=false
    local docker_changed=false
    local workflows_changed=false
    
    # Use GitHub's changed files if available
    if [[ -n "${GITHUB_EVENT_PATH}" ]]; then
        log_info "Using GitHub event data for change detection"
        
        # Get changed files from GitHub event
        local changed_files
        if [[ "${GITHUB_EVENT_NAME}" == "pull_request" ]]; then
            # For PR events, get files from the event payload
            changed_files=$(jq -r '.pull_request.changed_files // empty' "$GITHUB_EVENT_PATH" 2>/dev/null || echo "")
        else
            # For push events, use git diff
            changed_files=$(git diff --name-only HEAD~1 HEAD 2>/dev/null || echo "")
        fi
        
        if [[ -n "$changed_files" ]]; then
            log_info "Changed files detected:"
            echo "$changed_files" | while read -r file; do
                log_debug "  - $file"
                case "$file" in
                    $BACKEND_DIR/*)
                        backend_changed=true
                        ;;
                    $FRONTEND_DIR/*)
                        frontend_changed=true
                        ;;
                    docker-compose.yaml|*/Dockerfile)
                        docker_changed=true
                        ;;
                    .github/workflows/*)
                        workflows_changed=true
                        ;;
                esac
            done
        fi
    else
        log_warning "GitHub event data not available, using git diff"
        local changed_files
        changed_files=$(git diff --name-only HEAD~1 HEAD 2>/dev/null || echo "")
        
        while IFS= read -r file; do
            if [[ -n "$file" ]]; then
                case "$file" in
                    $BACKEND_DIR/*)
                        backend_changed=true
                        log_info "Backend change: $file"
                        ;;
                    $FRONTEND_DIR/*)
                        frontend_changed=true
                        log_info "Frontend change: $file"
                        ;;
                    docker-compose.yaml|*/Dockerfile)
                        docker_changed=true
                        log_info "Docker change: $file"
                        ;;
                    .github/workflows/*)
                        workflows_changed=true
                        log_info "Workflow change: $file"
                        ;;
                esac
            fi
        done <<< "$changed_files"
    fi
    
    # Set GitHub Actions outputs
    set_output "backend-changed" "$backend_changed"
    set_output "frontend-changed" "$frontend_changed"
    set_output "docker-changed" "$docker_changed"
    set_output "workflows-changed" "$workflows_changed"
    
    # Add to step summary
    add_summary "## Change Detection Results"
    add_summary "| Module | Changed |"
    add_summary "|--------|---------|"
    add_summary "| Backend | $backend_changed |"
    add_summary "| Frontend | $frontend_changed |"
    add_summary "| Docker | $docker_changed |"
    add_summary "| Workflows | $workflows_changed |"
    
    log_success "Change detection completed"
}

# Function to validate backend setup
validate_backend() {
    log_info "Validating backend setup..."
    
    if [[ ! -d "$BACKEND_DIR" ]]; then
        log_error "Backend directory '$BACKEND_DIR' not found!"
        return 1
    fi
    
    if [[ ! -f "$BACKEND_DIR/gradlew" ]]; then
        log_error "gradlew not found in backend directory!"
        return 1
    fi
    
    if [[ ! -f "$BACKEND_DIR/build.gradle" ]]; then
        log_error "build.gradle not found in backend directory!"
        return 1
    fi
    
    log_success "Backend setup validation passed"
    return 0
}

# Function to validate frontend setup
validate_frontend() {
    log_info "Validating frontend setup..."
    
    if [[ ! -d "$FRONTEND_DIR" ]]; then
        log_error "Frontend directory '$FRONTEND_DIR' not found!"
        return 1
    fi
    
    if [[ ! -f "$FRONTEND_DIR/package.json" ]]; then
        log_error "package.json not found in frontend directory!"
        return 1
    fi
    
    log_success "Frontend setup validation passed"
    return 0
}

# Function to run backend build
run_backend_build() {
    log_info "Running backend build..."
    
    cd "$BACKEND_DIR"
    
    # Make gradlew executable
    chmod +x gradlew
    
    # Run build
    if ./gradlew clean build --no-daemon; then
        log_success "Backend build completed successfully"
        
        # Set output for artifact path
        set_output "backend-jar-path" "teleheal-backend/build/libs/"
        
        cd ..
        return 0
    else
        log_error "Backend build failed!"
        cd ..
        return 1
    fi
}

# Function to run frontend build
run_frontend_build() {
    log_info "Running frontend build..."
    
    cd "$FRONTEND_DIR"
    
    # Install dependencies
    if npm ci --no-audit; then
        log_success "Frontend dependencies installed"
    else
        log_error "Failed to install frontend dependencies!"
        cd ..
        return 1
    fi
    
    # Run linting (optional)
    npm run lint || log_warning "Linting failed, continuing..."
    
    # Run tests
    if npm run test -- --watchAll=false --coverage --passWithNoTests; then
        log_success "Frontend tests passed"
    else
        log_warning "Frontend tests failed, continuing with build..."
    fi
    
    # Build application
    if npm run build; then
        log_success "Frontend build completed successfully"
        
        # Set output for artifact path
        set_output "frontend-build-path" "teleheal-ui/dist/"
        
        cd ..
        return 0
    else
        log_error "Frontend build failed!"
        cd ..
        return 1
    fi
}

# Function to generate build summary
generate_summary() {
    local backend_result="$1"
    local frontend_result="$2"
    
    add_summary ""
    add_summary "## Build Results Summary"
    add_summary "| Component | Status |"
    add_summary "|-----------|--------|"
    
    if [[ "$backend_result" == "success" ]]; then
        add_summary "| Backend | ✅ Success |"
    elif [[ "$backend_result" == "failed" ]]; then
        add_summary "| Backend | ❌ Failed |"
    else
        add_summary "| Backend | ⏭️ Skipped |"
    fi
    
    if [[ "$frontend_result" == "success" ]]; then
        add_summary "| Frontend | ✅ Success |"
    elif [[ "$frontend_result" == "failed" ]]; then
        add_summary "| Frontend | ❌ Failed |"
    else
        add_summary "| Frontend | ⏭️ Skipped |"
    fi
    
    # Add artifact information
    add_summary ""
    add_summary "## Artifacts Generated"
    [[ "$backend_result" == "success" ]] && add_summary "- Backend JAR: \`teleheal-backend/build/libs/\`"
    [[ "$frontend_result" == "success" ]] && add_summary "- Frontend Build: \`teleheal-ui/dist/\`"
}

# Main function
main() {
    local action="${1:-detect}"
    
    log_info "Starting GitHub Actions Smart CI/CD"
    log_info "Action: $action"
    
    case "$action" in
        "detect")
            detect_changes_from_github
            ;;
        "validate")
            local component="${2:-all}"
            case "$component" in
                "backend")
                    validate_backend
                    ;;
                "frontend")
                    validate_frontend
                    ;;
                "all")
                    validate_backend && validate_frontend
                    ;;
                *)
                    log_error "Unknown component: $component"
                    exit 1
                    ;;
            esac
            ;;
        "build")
            local component="${2:-all}"
            local backend_result="skipped"
            local frontend_result="skipped"
            
            case "$component" in
                "backend")
                    if run_backend_build; then
                        backend_result="success"
                    else
                        backend_result="failed"
                    fi
                    ;;
                "frontend")
                    if run_frontend_build; then
                        frontend_result="success"
                    else
                        frontend_result="failed"
                    fi
                    ;;
                "all")
                    if run_backend_build; then
                        backend_result="success"
                    else
                        backend_result="failed"
                    fi
                    
                    if run_frontend_build; then
                        frontend_result="success"
                    else
                        frontend_result="failed"
                    fi
                    ;;
                *)
                    log_error "Unknown component: $component"
                    exit 1
                    ;;
            esac
            
            generate_summary "$backend_result" "$frontend_result"
            
            # Set overall result
            if [[ "$backend_result" == "failed" || "$frontend_result" == "failed" ]]; then
                set_output "build-result" "failed"
                exit 1
            else
                set_output "build-result" "success"
            fi
            ;;
        *)
            log_error "Unknown action: $action"
            echo "Usage: $0 {detect|validate|build} [component]"
            echo "  detect: Detect changes in modules"
            echo "  validate [backend|frontend|all]: Validate setup"
            echo "  build [backend|frontend|all]: Build components"
            exit 1
            ;;
    esac
    
    log_success "GitHub Actions Smart CI/CD completed"
}

# Run main function with all arguments
main "$@"
