#!/bin/bash
# One-time environment setup for IPCV Assignment 2 on giano.cs.unibo.it (login node):
#
#     git clone https://github.com/LuyaoMa-ace/IPCV_HW.git /scratch.hpc/$USER/ipcv_a2/repo
#     cd /scratch.hpc/$USER/ipcv_a2/repo && bash cluster/setup_env.sh
#
# ISOLATION RULES (the account also contains a separate Big Data project environment, auto-activated by ~/.bashrc):
#   * everything lives under /scratch.hpc/$USER/ipcv_a2  (own venv "venv_ipcv", own data, own caches)
#   * this script NEVER touches ~/.bashrc, /scratch.hpc/$USER/venv, /scratch.hpc/$USER/project or hf_cache
#   * nothing is installed into any existing venv
set -eo pipefail

SCRATCH="/scratch.hpc/$USER/ipcv_a2"
mkdir -p "$SCRATCH"/data "$SCRATCH"/ckpts "$SCRATCH"/torch_cache

# ~/.bashrc auto-activates the other project's venv at every login. Take any venv out of PATH so that our
# own venv is built from the system Python and not from the other project's environment.
unset VIRTUAL_ENV PYTHONHOME
PATH="$(echo "$PATH" | tr ':' '\n' | grep -v '/venv[^/]*/bin$' | paste -sd: -)"
echo "building with: $(command -v python3)  ($(python3 --version))"

python3 -m venv "$SCRATCH/venv_ipcv"
source "$SCRATCH/venv_ipcv/bin/activate"
export PIP_NO_CACHE_DIR=1 TORCH_HOME="$SCRATCH/torch_cache"
pip install --upgrade pip

# The cu128 wheels are known to work on this cluster (the other project's venv uses them on l40 and rtx2080),
# so the documented "CUDA 11.8" limit is outdated; no version pinning, pip picks a matching torch/torchvision pair.
pip install torch torchvision --index-url https://download.pytorch.org/whl/cu128
pip install numpy pandas matplotlib jupyter ipykernel papermill

# Pre-download dataset and pretrained ResNet-18 weights here (compute nodes have internet too, but this makes
# the job independent of it). If the Oxford server is down: put fgvc-aircraft-2013b.tar.gz into $SCRATCH/data
# and run this block again - torchvision extracts an existing tarball.
IPCV_DATA_ROOT="$SCRATCH/data" python3 - <<'PY'
import os, torchvision
from torchvision.datasets import FGVCAircraft
FGVCAircraft(root=os.environ["IPCV_DATA_ROOT"], split="train", annotation_level="variant", download=True)
torchvision.models.resnet18(weights=torchvision.models.ResNet18_Weights.IMAGENET1K_V1)
import torch; print("torch", torch.__version__, "| dataset + resnet18 weights ready")
PY

echo "Environment ready: $SCRATCH/venv_ipcv"
