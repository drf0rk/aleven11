#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.
source /venv/main/bin/activate

echo "Starting custom setup script for A1111..."

# --- Add Git safety config ---
export GIT_CONFIG_GLOBAL=/tmp/temporary-git-config
git config --file $GIT_CONFIG_GLOBAL --add safe.directory '*'

# --- Configuration ---
A1111_DIR="/opt/workspace-internal/stable-diffusion-webui" # Docker-compatible path
SD_MODEL_DIR="$A1111_DIR/models/Stable-diffusion"
CN_MODEL_DIR="$A1111_DIR/models/ControlNet"
SAM_MODEL_DIR="$A1111_DIR/models/sam" # For Segment Anything models (manual download needed)
EXT_DIR="$A1111_DIR/extensions"

# List of extensions to clone (ensure Mikubill/sd-webui-controlnet is included if needed by other extensions, otherwise omit)
EXTENSIONS=(
    "https://github.com/AUTOMATIC1111/stable-diffusion-webui-promptgen"
    "https://github.com/continue-revolution/sd-webui-segment-anything"
    "https://github.com/modelscope/facechain"
    "https://github.com/glucauze/sd-webui-faceswaplab"
    "https://github.com/cheald/sd-webui-loractl"
    "https://github.com/light-and-ray/sd-webui-replacer"
    "https://github.com/gutris1/sd-hub"
    "https://github.com/Avaray/lora-keywords-finder"
    "https://github.com/kainatquaderee/sd-webui-reactor-Nsfw_freedom"
    "https://github.com/Haoming02/sd-webui-mosaic-outpaint"
    "https://github.com/zero01101/openOutpaint-webUI-extension"
    "https://github.com/Mikubill/sd-webui-controlnet" # Keep extension install
    "https://github.com/Coyote-A/ultimate-upscale-for-automatic1111"
    "https://github.com/zanllp/sd-webui-infinite-image-browsing"
    "https://github.com/alemelis/sd-webui-ar"
    "https://github.com/Uminosachi/sd-webui-inpaint-anything"

)

# SDXL Model URL and Filename
SDXL_MODEL_URL=""
SDXL_MODEL_FILENAME=""

# ControlNet Model URL and desired Filename
CN_MODEL_URL="https://huggingface.co/xinsir/controlnet-union-sdxl-1.0/resolve/main/diffusion_pytorch_model_promax.safetensors"
CN_MODEL_FILENAME="controlnet++_union_sdxl.safetensors" # Recommended name

# --- Ensure Directories Exist ---
echo "Ensuring directories exist..."
mkdir -p "$SD_MODEL_DIR"
mkdir -p "$CN_MODEL_DIR"
mkdir -p "$SAM_MODEL_DIR" # Create SAM dir, though models need manual download
mkdir -p "$EXT_DIR"

# --- Download Models ---
SDXL_MODEL_FILE_PATH="$SD_MODEL_DIR/$SDXL_MODEL_FILENAME"
echo "Checking for SDXL model: $SDXL_MODEL_FILENAME..."
if [ ! -s "$SDXL_MODEL_FILE_PATH" ] # Check if file exists and is non-empty
then
  echo "Downloading $SDXL_MODEL_FILENAME..."
  wget -nv -O "$SDXL_MODEL_FILE_PATH.tmp" "$SDXL_MODEL_URL" --show-progress || { echo "ERROR: SDXL download failed"; exit 1; }
  mv "$SDXL_MODEL_FILE_PATH.tmp" "$SDXL_MODEL_FILE_PATH"
else
  echo "SDXL model already exists, skipping download."
fi

CN_MODEL_FILE_PATH="$CN_MODEL_DIR/$CN_MODEL_FILENAME"
echo "Checking for ControlNet model: $CN_MODEL_FILENAME..."
if [ ! -s "$CN_MODEL_FILE_PATH" ] # Check if file exists and is non-empty
then
  echo "Downloading $CN_MODEL_FILENAME..."
  wget -nv -O "$CN_MODEL_FILE_PATH.tmp" "$CN_MODEL_URL" --show-progress || { echo "ERROR: ControlNet download failed"; exit 1; }
  mv "$CN_MODEL_FILE_PATH.tmp" "$CN_MODEL_FILE_PATH"
else
  echo "ControlNet model already exists, skipping download."
fi

# --- Clone Extensions ---
echo "Cloning/updating extensions..."
cd "$EXT_DIR"
for ext_url in "${EXTENSIONS[@]}"; do
  repo_name=$(basename "$ext_url" .git)
  if [ -d "$repo_name" ]; then
    echo "Extension $repo_name already exists. Attempting to pull latest changes..."
    (cd "$repo_name" && git pull) || echo "Could not pull latest changes for $repo_name. Continuing..."
  else
    echo "Cloning $repo_name..."
    git clone "$ext_url" || echo "Failed to clone $ext_url, but continuing..." # Continue even if one fails
  fi
done
cd "$A1111_DIR" # Go back to A1111 base directory

# --- Final Message ---
echo "Custom setup script finished successfully."
