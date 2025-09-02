FROM nvidia/cuda:12.4.1-cudnn-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive \
    PIP_PREFER_BINARY=1 \
    PYTHONUNBUFFERED=1

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

WORKDIR /workspace

# 1. 필수 패키지 설치
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      python3-dev \
      python3-pip \
      python3-venv \
      fonts-dejavu-core \
      rsync \
      git \
      jq \
      moreutils \
      aria2 \
      wget \
      curl \
      libglib2.0-0 \
      libsm6 \
      libgl1 \
      libxrender1 \
      libxext6 \
      ffmpeg \
      libgoogle-perftools4 \
      libtcmalloc-minimal4 \
      procps && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 2. ComfyUI + custom_nodes 설치
RUN git clone https://github.com/comfyanonymous/ComfyUI.git /workspace/ComfyUI && \
    git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git /workspace/ComfyUI/custom_nodes/ComfyUI-VideoHelperSuite 

# 3. Python venv 생성 및 requirements 설치
RUN python3 -m venv /workspace/venv && \
    /workspace/venv/bin/pip install --upgrade pip && \
    /workspace/venv/bin/pip install torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu129 && \
    /workspace/venv/bin/pip install --no-cache-dir -r /workspace/ComfyUI/requirements.txt && \
    /workspace/venv/bin/pip install --no-cache-dir -r /workspace/ComfyUI/custom_nodes/ComfyUI-VideoHelperSuite/requirements.txt && \
    /workspace/venv/bin/pip install runpod==1.7.10 boto3 requests

# 모델 폴더 생성
RUN mkdir -p /workspace/ComfyUI/models/unet && \
    mkdir -p /workspace/ComfyUI/models/text_encoders && \
    mkdir -p /workspace/ComfyUI/models/vae && \
    mkdir -p /workspace/ComfyUI/models/loras

# 모델 다운로드
RUN wget -O /workspace/ComfyUI/models/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors \
      "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors" && \
    wget -O /workspace/ComfyUI/models/unet/wan2.2_t2v_high_noise_14B_fp8_scaled.safetensors \
      "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/diffusion_models/wan2.2_t2v_high_noise_14B_fp8_scaled.safetensors" && \
    wget -O /workspace/ComfyUI/models/unet/wan2.2_t2v_low_noise_14B_fp8_scaled.safetensors \
      "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/diffusion_models/wan2.2_t2v_low_noise_14B_fp8_scaled.safetensors" && \
    wget -O /workspace/ComfyUI/models/vae/wan_2.1_vae.safetensors \
      "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors" && \
    wget -O /workspace/ComfyUI/models/loras/Wan21_T2V_14B_lightx2v_cfg_step_distill_lora_rank32.safetensors \
      "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Wan21_T2V_14B_lightx2v_cfg_step_distill_lora_rank32.safetensors"

# 6. RunPod 핸들러 및 설정 복사
COPY start.sh handler.py ./
COPY schemas /workspace/schemas
COPY workflows /workflows

RUN chmod +x /workspace/start.sh
ENTRYPOINT ["/workspace/start.sh"]