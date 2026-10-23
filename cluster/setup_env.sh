#!/bin/bash
# One-time environment setup. Run it on giano.cs.unibo.it (login node):   bash cluster/setup_env.sh
#
# Everything big goes to /scratch.hpc/$USER/ipcv because $HOME has a 400 MB quota.
# NOTE: the DISI instructions are ambiguous about whether /scratch.hpc is visible from the GPU nodes.
#       Verify it once with a tiny job (e.g. `sbatch --wrap="ls /scratch.hpc/$USER"` with --gres=gpu:1)
#       before submitting the real one; if it is NOT visible, ask the lab staff where to put large data.
set -euo pipefail

SCRATCH="/scratch.hpc/$USER/ipcv"
mkdir -p "$SCRATCH"/data "$SCRATCH"/ckpts

python3 -m venv "$SCRATCH/venv"
source "$SCRATCH/venv/bin/activate"
pip3 install --no-cache-dir --upgrade pip

# The cluster has NVIDIA driver 535 / CUDA 11.8 libraries -> use the cu118 wheels (PyTorch <= 2.7 ships them).
# If pip cannot find these exact versions, try torch==2.6.0 torchvision==0.21.0.
pip3 install --no-cache-dir torch==2.7.1 torchvision==0.22.1 --index-url https://download.pytorch.org/whl/cu118
pip3 install --no-cache-dir numpy pandas matplotlib jupyter ipykernel papermill
pip3 cache purge || true

# Download the dataset here, on the login node (internet access from the GPU nodes is not documented).
IPCV_DATA_ROOT="$SCRATCH/data" python3 - <<'PY'
import os
from torchvision.datasets import FGVCAircraft
FGVCAircraft(root=os.environ["IPCV_DATA_ROOT"], split="train", annotation_level="variant", download=True)
print("dataset ready in", os.environ["IPCV_DATA_ROOT"])
PY
# If the download fails (the Oxford server is sometimes down), put fgvc-aircraft-2013b.tar.gz into
# $SCRATCH/data and run this last step again: torchvision extracts an existing tarball.

echo "Environment ready: $SCRATCH/venv"
