#!/bin/bash
# Run the whole notebook in one go on a GPU node of the DISI cluster (run `bash cluster/setup_env.sh` first).
#
#   cd /scratch.hpc/$USER/ipcv_a2/repo
#   squeue -u $USER                                          # see what the other project is already running
#   sbatch cluster/run_notebook.sbatch                       # fresh run of everything
#   sbatch --export=ALL,IPCV_SKIP_DONE=1 cluster/run_notebook.sbatch
#                                                            # re-submit after a crash / time-out: experiments already
#                                                            # stored in results.json are skipped, the rest is trained
#
# Progress: `tail -f ipcv-<jobid>.log` (papermill streams every cell output into the log).
# The executed notebook (with all outputs) is written cell by cell, so even a killed job leaves a partial result.
#
# The partition is rtx2080 on purpose: the l40 nodes are usually busy with the other project, and ResNet-18 /
# the small custom CNN fit comfortably in 11 GB.
#
#SBATCH --job-name=ipcv-a2
#SBATCH --mail-type=ALL
#SBATCH --mail-user=name.surname@studio.unibo.it      # TODO: put your address here
#SBATCH --time=24:00:00                               # TODO: check the limit with `scontrol show partition rtx2080`
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=4                             # rtx2080 nodes have a quad-core CPU; data loading is CPU-bound
#SBATCH --partition=rtx2080
#SBATCH --output=ipcv-%j.log
#SBATCH --gres=gpu:1                                  # must stay as is: it is what activates the GPU

set -eo pipefail
SCRATCH="/scratch.hpc/$USER/ipcv_a2"

# Do not inherit the other project's environment from the submitting shell; use only our own venv.
unset VIRTUAL_ENV PYTHONHOME
source "$SCRATCH/venv_ipcv/bin/activate"

export IPCV_DATA_ROOT="$SCRATCH/data"
export IPCV_CKPT_DIR="$SCRATCH/ckpts"                 # results.json is written next to this folder ($SCRATCH)
export IPCV_NUM_WORKERS="${SLURM_CPUS_PER_TASK:-2}"
export IPCV_SKIP_DONE="${IPCV_SKIP_DONE:-0}"
export TORCH_HOME="$SCRATCH/torch_cache"
export PYTHONUNBUFFERED=1

NB="${1:-assignment_module_two (4).ipynb}"
OUT="${2:-executed_assignment_module_two.ipynb}"

nvidia-smi || true
python3 -c "import torch; print('torch', torch.__version__, '| cuda available:', torch.cuda.is_available())"
papermill "$NB" "$OUT" -k python3 --log-output --no-progress-bar
echo "Finished. Executed notebook: $OUT   results: $SCRATCH/results.json"
