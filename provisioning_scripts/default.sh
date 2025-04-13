#!/bin/bash
source /venv/main/bin/activate
set -e # Exit immediately if a command exits with a non-zero status.
# set -x # Uncomment for detailed command execution logging
wget ... || { echo "Download failed"; exit 1; }
echo "Starting custom setup script for A1111..."

export GIT_CONFIG_GLOBAL=/tmp/temporary-git-config
git config --file $GIT_CONFIG_GLOBAL --add safe.directory '*'

# --- Configuration ---
A1111_DIR="/opt/workspace-internal/stable-diffusion-webui" # Confirmed path from logs/docs
SD_MODEL_DIR="$A1111_DIR/models/Stable-diffusion"
CN_MODEL_DIR="$A1111_DIR/models/ControlNet"
SAM_MODEL_DIR="$A1111_DIR/models/sam" # For Segment Anything models (manual download needed)
EXT_DIR="$A1111_DIR/extensions"

# List of extensions to clone (ensure Mikubill/sd-webui-controlnet is included if needed by other extensions, otherwise omit)
EXTENSIONS=(
  "https://github.com/Mikubill/sd-webui-controlnet.git" # Keeping this as it's often required by other CN-related extensions
  "https://github.com/fkunn1326/openpose-editor.git"
  "https://github.com/camenduru/stable-diffusion-webui-huggingface.git"
  "https://github.com/camenduru/stable-diffusion-webui-tunnels.git"
  "https://github.com/etherealxx/batchlinks-webui.git"
  "https://github.com/camenduru/stable-diffusion-webui-catppuccin.git"
  "https://github.com/KohakuBlueleaf/a1111-sd-webui-locon.git"
  "https://github.com/AUTOMATIC1111/stable-diffusion-webui-rembg.git"
  "https://github.com/ashen-sensored/stable-diffusion-webui-two-shot.git"
  "https://github.com/thomasasfk/sd-webui-aspect-ratio-helper.git"
  "https://github.com/tjm35/asymmetric-tiling-sd-webui.git"
  "https://github.com/pkuliyi2015/multidiffusion-upscaler-for-automatic1111.git"
  "https://github.com/Coyote-A/ultimate-upscale-for-automatic1111.git"
  "https://github.com/kohya-ss/sd-webui-additional-networks.git"
  "https://github.com/AlUlkesh/stable-diffusion-webui-images-browser.git"
  "https://github.com/continue-revolution/sd-webui-segment-anything.git"
  "https://github.com/civitai/sd_civitai_extension.git"
  "https://github.com/Gourieff/sd-webui-reactor.git"
  "https://github.com/hnmr293/posex.git"
  "https://github.com/nonnonstop/sd-webui-3d-open-pose-editor.git"
  "https://github.com/v8hid/infinite-image-Browse.git"
  "https://github.com/toshiaki1729/stable-diffusion-webui-dataset-tag-editor.git"
  "https://github.com/toriato/stable-diffusion-webui-wd14-tagger.git"
  "https://github.com/adieyal/sd-dynamic-prompts.git"
)

# SDXL Model URL and Filename
SDXL_MODEL_URL="https://huggingface.co/Red1618/tEST2/resolve/main/Schlip.safetensors"
SDXL_MODEL_FILENAME="Schlip.safetensors"

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
  wget -nv -O "$SDXL_MODEL_FILE_PATH.tmp" "$SDXL_MODEL_URL" --show-progress && mv "$SDXL_MODEL_FILE_PATH.tmp" "$SDXL_MODEL_FILE_PATH" || echo "ERROR: Failed to download SDXL model."
else
  echo "SDXL model already exists, skipping download."
fi

CN_MODEL_FILE_PATH="$CN_MODEL_DIR/$CN_MODEL_FILENAME"
echo "Checking for ControlNet model: $CN_MODEL_FILENAME..."
if [ ! -s "$CN_MODEL_FILE_PATH" ] # Check if file exists and is non-empty
then
  echo "Downloading $CN_MODEL_FILENAME..."
  wget -nv -O "$CN_MODEL_FILE_PATH.tmp" "$CN_MODEL_URL" --show-progress && mv "$CN_MODEL_FILE_PATH.tmp" "$CN_MODEL_FILE_PATH" || echo "ERROR: Failed to download ControlNet model."
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

# --- REMOVED SECTION THAT MODIFIED webui-user.sh ---

# --- Final Message ---
echo "Custom setup script finished successfully."
