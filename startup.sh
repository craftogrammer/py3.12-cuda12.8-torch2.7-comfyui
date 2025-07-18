#!/bin/bash
set -e

# Logging setup
LOG_FILE="/workspace/startup.log"
exec 2> >(tee -a "$LOG_FILE")

log_info() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" | tee -a "$LOG_FILE"
}

print_header() {
    echo "================================================"
    echo "  $1"
    echo "================================================"
}

print_step() {
    echo ""
    echo "📋 STEP $1: $2"
    echo "----------------------------------------"
}

print_success() {
    echo "✅ $1"
}

print_warning() {
    echo "⚠️  $1"
}

print_error() {
    echo "❌ $1"
}

# Color codes for better visibility
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}"
print_header "🚀 ComfyUI Fresh Setup & Restore"
echo -e "${NC}"

log_info "=== Starting ComfyUI Fresh Setup Process ==="

# Define paths
COMFYUI_DIR="/workspace/ComfyUI"
BACKUP_DIR="/workspace/.backup_temp"
PERSISTENT_FOLDERS=("models" "output" "input" "user")

# Function to backup persistent folders
backup_persistent_folders() {
    print_step "1" "Moving persistent folders to backup"
    
    if [ ! -d "$COMFYUI_DIR" ]; then
        print_warning "ComfyUI directory does not exist, skipping backup"
        log_info "ComfyUI directory not found, no backup needed"
        return 0
    fi
    
    # Create backup directory
    mkdir -p "$BACKUP_DIR"
    
    for folder in "${PERSISTENT_FOLDERS[@]}"; do
        source_path="$COMFYUI_DIR/$folder"
        backup_path="$BACKUP_DIR/$folder"
        
        if [ -d "$source_path" ]; then
            echo "📁 Moving $folder to backup..."
            log_info "Moving $folder from $source_path to $backup_path"
            
            # Move the folder instead of copying
            if mv "$source_path" "$backup_path"; then
                print_success "Moved $folder to backup"
                log_info "Successfully moved $folder to backup"
            else
                print_error "Failed to move $folder"
                log_error "mv failed for $folder"
                return 1
            fi
        else
            print_warning "$folder does not exist, skipping"
            log_info "$folder not found, skipping backup"
        fi
    done
    
    echo ""
}

# Function to restore persistent folders
restore_persistent_folders() {
    print_step "6" "Restoring persistent folders"
    
    if [ ! -d "$BACKUP_DIR" ]; then
        print_warning "No backup directory found, skipping restore"
        log_info "No backup directory found"
        return 0
    fi
    
    for folder in "${PERSISTENT_FOLDERS[@]}"; do
        backup_path="$BACKUP_DIR/$folder"
        restore_path="$COMFYUI_DIR/$folder"
        
        if [ -d "$backup_path" ]; then
            echo "📁 Moving $folder back from backup..."
            log_info "Moving $folder from $backup_path to $restore_path"
            
            # Ensure target directory exists
            mkdir -p "$(dirname "$restore_path")"
            
            # Remove existing folder if it exists (from fresh ComfyUI)
            if [ -d "$restore_path" ]; then
                rm -rf "$restore_path"
            fi
            
            # Move the folder back from backup
            if mv "$backup_path" "$restore_path"; then
                print_success "Moved $folder back from backup"
                log_info "Successfully moved $folder back from backup"
            else
                print_error "Failed to move $folder back"
                log_error "mv restore failed for $folder"
                return 1
            fi
        else
            print_warning "No backup found for $folder"
            log_info "No backup found for $folder"
        fi
    done
    
    # Clean up backup directory (should be empty now)
    if [ -d "$BACKUP_DIR" ]; then
        rmdir "$BACKUP_DIR" 2>/dev/null || true
    fi
    
    print_success "Backup directory cleaned"
    log_info "Backup directory removed"
    
    echo ""
}

# Function to install GPU wheels
install_gpu_wheels() {
    print_step "5" "Installing GPU wheels"
    
    if [ -d "/opt/wheels" ] && [ "$(ls -A /opt/wheels 2>/dev/null)" ]; then
        log_info "Installing pre-compiled GPU packages..."
        
        for wheel in /opt/wheels/*.whl; do
            if [ -f "$wheel" ]; then
                package_name=$(basename "$wheel" | cut -d'-' -f1)
                echo "📦 Installing $package_name..."
                log_info "Installing $package_name from wheel"
                
                if pip install --no-cache-dir "$wheel"; then
                    print_success "Installed $package_name"
                    log_info "Successfully installed $package_name"
                else
                    print_error "Failed to install $package_name"
                    log_error "Failed to install $wheel"
                fi
            fi
        done
        
        print_success "GPU packages installation completed"
        log_info "GPU packages installation completed"
    else
        print_warning "No pre-compiled wheels found"
        log_info "No pre-compiled wheels found"
    fi
    
    echo ""
}

# Function to setup ComfyUI-Manager
setup_comfyui_manager() {
    print_step "4" "Setting up ComfyUI-Manager"
    
    COMFY_MANAGER_DIR="$COMFYUI_DIR/custom_nodes/ComfyUI-Manager"
    
    # Remove existing manager if it exists
    if [ -d "$COMFY_MANAGER_DIR" ]; then
        echo "🧹 Removing existing ComfyUI-Manager..."
        rm -rf "$COMFY_MANAGER_DIR"
    fi
    
    echo "📦 Cloning ComfyUI-Manager..."
    log_info "Cloning ComfyUI-Manager"
    
    if git clone https://github.com/ltdrdata/ComfyUI-Manager.git "$COMFY_MANAGER_DIR"; then
        print_success "ComfyUI-Manager cloned"
        log_info "ComfyUI-Manager cloned successfully"
    else
        print_error "Failed to clone ComfyUI-Manager"
        log_error "Failed to clone ComfyUI-Manager"
        return 1
    fi
    
    # Install requirements
    if [ -f "$COMFY_MANAGER_DIR/requirements.txt" ]; then
        echo "📦 Installing ComfyUI-Manager requirements..."
        log_info "Installing ComfyUI-Manager requirements"
        
        if pip install --no-cache-dir -r "$COMFY_MANAGER_DIR/requirements.txt"; then
            print_success "ComfyUI-Manager requirements installed"
            log_info "ComfyUI-Manager requirements installed"
        else
            print_error "Failed to install ComfyUI-Manager requirements"
            log_error "Failed to install ComfyUI-Manager requirements"
            return 1
        fi
    fi
    
    echo ""
}

# Function to setup ComfyUI
setup_comfyui() {
    print_step "3" "Setting up ComfyUI"
    
    # Remove existing ComfyUI
    if [ -d "$COMFYUI_DIR" ]; then
        echo "🧹 Removing existing ComfyUI..."
        log_info "Removing existing ComfyUI directory"
        rm -rf "$COMFYUI_DIR"
    fi
    
    # Clone fresh ComfyUI
    echo "📦 Cloning ComfyUI..."
    log_info "Cloning ComfyUI repository"
    
    if git clone https://github.com/comfyanonymous/ComfyUI.git "$COMFYUI_DIR"; then
        print_success "ComfyUI cloned"
        log_info "ComfyUI cloned successfully"
    else
        print_error "Failed to clone ComfyUI"
        log_error "Failed to clone ComfyUI"
        return 1
    fi
    
    # Install requirements
    echo "📦 Installing ComfyUI requirements..."
    log_info "Installing ComfyUI requirements"
    
    if pip install --no-cache-dir -r "$COMFYUI_DIR/requirements.txt"; then
        print_success "ComfyUI requirements installed"
        log_info "ComfyUI requirements installed"
    else
        print_error "Failed to install ComfyUI requirements"
        log_error "Failed to install ComfyUI requirements"
        return 1
    fi
    
    echo ""
}

# Function to run health checks
run_health_checks() {
    print_step "7" "Running health checks"
    
    log_info "Running basic health check"
    
    # Check PyTorch CUDA
    if python -c "import torch; print(f'PyTorch CUDA: {torch.cuda.is_available()}')" 2>/dev/null; then
        print_success "PyTorch CUDA available"
        log_info "PyTorch CUDA check passed"
    else
        print_warning "PyTorch CUDA not available"
        log_info "PyTorch CUDA check failed"
    fi
    
    # Check if ComfyUI directory exists
    if [ -d "$COMFYUI_DIR" ]; then
        print_success "ComfyUI directory exists"
        log_info "ComfyUI directory check passed"
    else
        print_error "ComfyUI directory missing"
        log_error "ComfyUI directory check failed"
        return 1
    fi
    
    echo ""
}

# Main execution flow
main() {
    log_info "=== Starting ComfyUI Fresh Setup Process ==="
    
    # Step 1: Backup persistent folders
    backup_persistent_folders
    
    # Step 2: Create model directories (will be restored later)
    print_step "2" "Preparing directory structure"
    mkdir -p "$COMFYUI_DIR/models"/{vae/wan2,diffusion_models/wan2/addons,loras/wan2,text_encoders/wan2,clip_vision}
    print_success "Directory structure prepared"
    echo ""
    
    # Step 3: Setup fresh ComfyUI
    setup_comfyui
    
    # Step 4: Setup ComfyUI-Manager
    setup_comfyui_manager
    
    # Step 5: Install GPU wheels
    install_gpu_wheels
    
    # Step 6: Restore persistent folders
    restore_persistent_folders
    
    # Step 7: Run health checks
    run_health_checks
    
    # Final step: Start services
    print_step "8" "Starting services"
    log_info "Starting ComfyUI and Ollama services"
    
    echo -e "${GREEN}"
    print_header "🎉 Setup Complete! Starting services..."
    echo -e "${NC}"
    
    # Start Ollama in background
    echo "🤖 Starting Ollama service..."
    if command -v ollama &> /dev/null; then
        ollama serve &
        OLLAMA_PID=$!
        print_success "Ollama service started (PID: $OLLAMA_PID)"
        log_info "Ollama service started with PID: $OLLAMA_PID"
        
        # Wait for Ollama to initialize
        sleep 3
        
        # Optional: Pull default model if specified
        if [ -n "${DEFAULT_OLLAMA_MODEL:-}" ]; then
            echo "📦 Pulling default Ollama model: $DEFAULT_OLLAMA_MODEL"
            ollama pull "$DEFAULT_OLLAMA_MODEL" || print_warning "Failed to pull model: $DEFAULT_OLLAMA_MODEL"
        fi
    else
        print_warning "Ollama not found, skipping Ollama service"
        log_warning "Ollama not installed"
    fi
    
    echo ""
    echo "📊 Access ComfyUI at: http://localhost:8188"
    echo "🤖 Access Ollama API at: http://localhost:11434"
    echo "📁 Workspace: /workspace"
    echo "📋 Logs: /workspace/startup.log"
    
    cd "$COMFYUI_DIR"
    python main.py --listen --port 8188
}

# Execute main function
main
