#!/bin/bash
# Run the whole notebook in one go on a GPU node of the DISI cluster.
#
#   sbatch cluster/run_notebook.sbatch                      # fresh run of everything
#   sbatch --export=ALL,IPCV_SKIP_DONE=1 cluster/run_notebook.sbatch
#                                                           # re-submit after a crash / time-out: experiments that are
#                                                           # already in results.json are skipped, the rest is trained
#
# Progress: `tail -f ipcv-<jobid>.log` (papermill streams every cell output into the log).
# The executed notebook (with all outputs) is written cell by cell, so a killed job still leaves a partial result.
#
#SBATCH --job-name=ipcv-a2
#SBATCH --mail-type=ALL
#SBATCH --mail-user=name.surname@studio.unibo.it      # TODO: put your address here
#SBATCH --time=24:00:00                               # TODO: check the limit with `scontrol show partition l40`
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=4                             # data loading is CPU-bound; l40 nodes have 8 cores (remove if rejected)
#SBATCH --partition=l40                               # or rtx2080 (11 GB) - 80 epochs of ResNet-18 @224px fit in both
#SBATCH --output=ipcv-%j.log
#SBATCH --gres=gpu:1                                  # must stay as is: it is what activates the GPU

set -euo pipefail
SCRATCH="/scratch.hpc/$USER/ipcv"
source "$SCRATCH/venv/bin/activate"

export IPCV_DATA_ROOT="$SCRATCH/data"
export IPCV_CKPT_DIR="$SCRATCH/ckpts"                 # results.json is written next to this folder
export IPCV_NUM_WORKERS="${SLURM_CPUS_PER_TASK:-2}"
export IPCV_SKIP_DONE="${IPCV_SKIP_DONE:-0}"
export PYTHONUNBUFFERED=1

NB="${1:-assignment_module_two (4).ipynb}"
OUT="${2:-executed_assignment_module_two.ipynb}"

nvidia-smi || true
python3 -c "import torch; print('torch', torch.__version__, '| cuda available:', torch.cuda.is_available())"
papermill "$NB" "$OUT" -k python3 --log-output --no-progress-bar
echo "Finished. Executed notebook: $OUT   results: $SCRATCH/results.json"
