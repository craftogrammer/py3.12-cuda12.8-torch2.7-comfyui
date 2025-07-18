# Optimized ComfyUI Dockerfile for RunPod
FROM nvidia/cuda:12.8.1-devel-ubuntu24.04 AS builder

# Build environment
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-pip python3-dev build-essential git curl ca-certificates python3.12-dev gcc g++ make && \
    ln -sf /usr/bin/python3 /usr/bin/python && \
    ln -sf /usr/bin/pip3 /usr/bin/pip && \
    rm -f /usr/lib/python*/EXTERNALLY-MANAGED && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install PyTorch with CUDA 12.8
RUN pip install --no-cache-dir torch torchvision torchaudio \
    --extra-index-url https://download.pytorch.org/whl/cu128

# Copy pre-compiled wheels (if available)
COPY *.whl /opt/wheels/
RUN mkdir -p /opt/wheels

# Runtime image
FROM nvidia/cuda:12.8.1-runtime-ubuntu24.04

# Runtime environment
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    CUDA_HOME=/usr/local/cuda \
    TORCHINDUCTOR_CACHE_DIR=/root/.torch_inductor_cache \
    TORCHINDUCTOR_FX_GRAPH_CACHE=1 \
    TORCHINDUCTOR_AUTOGRAD_CACHE=1

# Copy Python packages from builder
COPY --from=builder /usr/local/lib/python3.12/dist-packages /usr/local/lib/python3.12/dist-packages
COPY --from=builder /usr/local/bin /usr/local/bin
COPY --from=builder /opt/wheels /opt/wheels

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-pip git wget aria2 curl ca-certificates \
    libsm6 libxext6 libxrender-dev libglib2.0-0 libgomp1 \
    software-properties-common build-essential python3.12-dev gcc g++ make \
    pciutils lshw && \
    add-apt-repository ppa:savoury1/ffmpeg4 -y && \
    apt-get update && apt-get install -y --no-install-recommends ffmpeg && \
    ln -sf /usr/bin/python3 /usr/bin/python && \
    ln -sf /usr/bin/pip3 /usr/bin/pip && \
    rm -f /usr/lib/python*/EXTERNALLY-MANAGED && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Ollama
RUN curl -fsSL https://ollama.com/install.sh | sh
# Copy startup script
COPY startup.sh /usr/local/bin/startup.sh
RUN chmod +x /usr/local/bin/startup.sh

# Create workspace
WORKDIR /workspace
EXPOSE 8188

CMD ["/usr/local/bin/startup.sh"]