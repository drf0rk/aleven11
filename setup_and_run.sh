#!/bin/bash
# Log files for debugging startup
LOG_FILE="/workspace/onstart.log"
JUPYTER_LOG="/workspace/jupyter.log"
ROOP_LOG="/workspace/roop.log"

# --- Define Repository Details ---
# Adjust REPO_DIR if your actual clone directory name is different
REPO_DIR="/workspace/Roop-Unleashed-Runpod"
# Make sure this is the correct URL for the repo you want!
REPO_URL="https://codeberg.org/Cognibuild/ROOP-FLOYD"
# --- End Definitions ---

echo "Starting On-Start Script..." > $LOG_FILE

# Navigate to workspace first
cd /workspace || { echo "ERROR: Failed to cd into /workspace" >> $LOG_FILE; exit 1; }
echo "Ensuring repository exists at $REPO_DIR..." >> $LOG_FILE

# Check if repo dir exists, if not, clone it
if [ ! -d "$REPO_DIR" ]; then
    echo "Repository directory not found. Cloning '$REPO_URL' into '$REPO_DIR'..." >> $LOG_FILE
    # Clone the specific repo into the target directory name
    git clone "$REPO_URL" "$REPO_DIR" >> $LOG_FILE 2>&1
    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to clone repository." >> $LOG_FILE
        exit 1
    fi
    echo "Repository cloned successfully." >> $LOG_FILE
else
    echo "Repository directory '$REPO_DIR' already exists." >> $LOG_FILE
    # Optional: You could add 'git pull' here if you want it to update on restarts
    # echo "Attempting git pull..." >> $LOG_FILE
    # cd "$REPO_DIR" && git pull origin main >> $LOG_FILE 2>&1 # Adjust branch if needed
    # cd /workspace # Go back in case pull failed
fi

# Now, the critical cd command using the variable
cd "$REPO_DIR" || { echo "ERROR: Failed to cd into '$REPO_DIR' after clone/check." >> $LOG_FILE; exit 1; }
echo "Changed directory to $(pwd)" >> $LOG_FILE

# --- Stop old processes ---
echo "Stopping old processes..." >> $LOG_FILE
pkill -f "jupyter-lab"
pkill -f "python run.py"
sleep 2

# --- Activate virtual environment ---
# (Assuming it exists from prior manual setup or first-time auto-setup if implemented)
if [ -d "venv/bin" ]; then
  source venv/bin/activate >> $LOG_FILE 2>&1
  echo "Virtualenv activated." >> $LOG_FILE
else
  echo "ERROR: venv not found in $(pwd). Please SSH in and run setup steps first." >> $LOG_FILE
  # Consider adding the setup commands here if you want auto-setup on first run
  exit 1
fi

# --- Start JupyterLab ---
echo "Launching JupyterLab..." >> $LOG_FILE
nohup jupyter lab --port=8080 --ip=0.0.0.0 --no-browser --allow-root --notebook-dir=/workspace/ >> $JUPYTER_LOG 2>&1 &
JUPYTER_PID=$! # Get the process ID
echo "JupyterLab launched with PID $JUPYTER_PID. Check $JUPYTER_LOG for token and details." >> $LOG_FILE
sleep 5 # Give Jupyter a moment to start

# --- Start Roop UI ---
echo "Launching Roop UI (run.py)..." >> $LOG_FILE
# Make sure run.py is in the root of REPO_DIR or adjust path if needed
nohup python run.py --listen --port 7860 >> $ROOP_LOG 2>&1 &
ROOP_PID=$! # Get the process ID
echo "Roop UI launched with PID $ROOP_PID. Check $ROOP_LOG for details." >> $LOG_FILE

echo "On-Start Script finished." >> $LOG_FILE
exit 0