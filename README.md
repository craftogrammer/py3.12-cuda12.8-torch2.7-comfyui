# ComfyUI + Ollama Docker Image

[![Docker](https://img.shields.io/badge/Docker-Ready-blue.svg)](https://docker.com)
[![CUDA](https://img.shields.io/badge/CUDA-12.8-green.svg)](https://developer.nvidia.com/cuda-toolkit)
[![Python](https://img.shields.io/badge/Python-3.12-blue.svg)](https://python.org)
[![PyTorch](https://img.shields.io/badge/PyTorch-2.7-orange.svg)](https://pytorch.org)

GPU-optimized Docker image for [ComfyUI](https://github.com/comfyanonymous/ComfyUI) and [Ollama](https://ollama.com) with automated setup and persistent storage management.

## 🎯 Features & What's Included

### Key Features
- **🚀 Fresh Setup**: Automated ComfyUI installation with persistent data recovery
- **🔥 GPU Ready**: NVIDIA CUDA 12.8 with PyTorch 2.7 support
- **🧠 AI Tools**: ComfyUI + Ollama pre-installed
- **💾 Smart Backup**: Preserves models, outputs, and user data during updates
- **📦 Pre-compiled**: GPU packages included for faster startup
- **🔧 Auto-Manager**: ComfyUI-Manager included for easy extension management

### Pre-installed Components
- **ComfyUI**: Latest stable version
- **ComfyUI-Manager**: For easy node management
- **Ollama**: Local LLM inference engine
- **GPU Wheels**: Pre-compiled packages (flash_attn, sageattention)
- **PyTorch**: CUDA 12.8 optimized build

### Specifications
| Component | Version | Description |
|-----------|---------|-------------|
| **Base OS** | Ubuntu 24.04 | Latest LTS with CUDA runtime |
| **Python** | 3.12 | Latest stable Python |
| **CUDA** | 12.8.1 | NVIDIA CUDA Toolkit |
| **PyTorch** | 2.7 | GPU-accelerated deep learning |
| **ComfyUI** | Latest | Node-based stable diffusion UI |
| **Ollama** | Latest | Local LLM inference engine |

### Data Persistence
The container automatically manages persistent data during updates:

**Preserved ComfyUI Folders from remote storage:**
- **`models/`** - Your downloaded AI models
- **`output/`** - Generated images and videos
- **`input/`** - Input files
- **`user/`** - User settings and workflows

## 🎮 Usage

### ComfyUI
1. Access ComfyUI at `http://localhost:8188`
2. Load workflows and connect models
3. Models are auto-detected in `/workspace/ComfyUI/models/`
4. Use ComfyUI-Manager for installing custom nodes

### Ollama
Ollama service starts automatically when the container runs.

```bash
# Check if Ollama is running (should show empty list initially)
docker exec -it comfyui-container ollama list

# Pull and run the recommended model
docker exec -it comfyui-container ollama pull qwen3:8b
docker exec -it comfyui-container ollama run qwen3:8b

# Set custom default model (optional)
docker run -e DEFAULT_OLLAMA_MODEL=qwen3:8b ...
```

**💡 Tips:**
- **VRAM Requirements**: For ComfyUI + Ollama together, use **48GB+ GPU** (L40S recommended on RunPod)
- **Recommended Model**: `qwen3:8b` (~5GB VRAM) works well with ComfyUI Ollama nodes
- **ComfyUI Integration**: Use Ollama nodes in ComfyUI to connect to `http://localhost:11434`
- **No Default Model**: Container serves Ollama API only, you choose which models to pull

### Access Services
Once the container is running:

- **ComfyUI Interface**: `http://localhost:8188` (or your RunPod URL)
- **Ollama API**: `http://localhost:11434`
- **Logs**: Check `/workspace/startup.log` for detailed startup logs

## 🔧 RunPod Setup

### Manual RunPod Setup
1. **Create Pod**: Select GPU instance (RTX 4090+ recommended)
2. **Docker Image**: `craftogrammer/py3.12-cuda12.8-torch2.7-comfyui:latest`
3. **Ports**: Expose `8188` (ComfyUI) and `11434` (Ollama)
4. **Volume**: Mount `/workspace` for persistent storage
5. **Start**: Container auto-starts ComfyUI and Ollama on boot

## 🚀 Local Setup

### Pull from Docker Hub
```bash
# Pull the latest image
docker pull craftogrammer/py3.12-cuda12.8-torch2.7-comfyui:latest

# Run with persistent storage locally
docker run -it --gpus all \
  -v $(pwd)/comfyui-workspace:/workspace \
  -p 8188:8188 \
  -p 11434:11434 \
  --name comfyui-container \
  craftogrammer/py3.12-cuda12.8-torch2.7-comfyui:latest
```

### Build Locally
```bash
# Clone the repository
git clone https://github.com/craftogrammer/py3.12-cuda12.8-torch2.7-comfyui.git
cd py3.12-cuda12.8-torch2.7-comfyui

# Build the image
docker build -t comfyui-local .

# Run the container
docker run -it --gpus all \
  -v $(pwd)/workspace:/workspace \
  -p 8188:8188 \
  -p 11434:11434 \
  --name comfyui-local-container \
  comfyui-local
```

## 📦 Publishing (For Developers)

```bash
# Tag for repository
docker tag comfyui-local craftogrammer/py3.12-cuda12.8-torch2.7-comfyui:latest

# Push to Docker Hub
docker push craftogrammer/py3.12-cuda12.8-torch2.7-comfyui:latest
```

## 🔍 Troubleshooting

### Container Management
```bash
# Check container status
docker ps -a

# View real-time logs
docker logs -f comfyui-container

# Restart container
docker restart comfyui-container

# Access container shell
docker exec -it comfyui-container bash
```

### Health Checks
```bash
# Check GPU availability
docker exec -it comfyui-container nvidia-smi

# Test PyTorch CUDA
docker exec -it comfyui-container python -c "import torch; print(f'CUDA: {torch.cuda.is_available()}')"

# Check disk usage
docker exec -it comfyui-container df -h
```

### Common Issues

| Issue | Solution |
|-------|----------|
| **Port 8188 busy** | Use different port: `-p 8189:8188` |
| **Out of memory** | Reduce model size or increase GPU RAM |
| **Slow startup** | Check logs in `/workspace/startup.log` |
| **Models missing** | Verify volume mount: `-v /path/to/workspace:/workspace` |

---

## 🇮🇳 Made with Love from India

**🎉 Ready to create amazing AI art and run powerful LLMs locally!**