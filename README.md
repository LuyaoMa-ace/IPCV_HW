# IPCV_HW

Homework assignments for the Image Processing and Computer Vision (IPCV) course. University of Bologna, Master in AI (2025-2026).

## Assignment Module 2 — aircraft classification (FGVC-Aircraft)

`assignment_module_two.ipynb` is the complete, executed notebook (code, outputs, plots and the written analysis):

- **Part 1**: a ResNet-style CNN trained from scratch, with an ablation study (BatchNorm, residual connections, dropout, global average pooling, augmentation, LR schedule, capacity, activation, input resolution).
- **Part 2**: a pretrained ResNet-18, fine-tuned (2A with the Part 1 hyper-parameters, 2B tuned), with ablations, a learning-rate check, a three-seed robustness check and an error analysis.

| Path | Content |
|---|---|
| `assignment_module_two.ipynb` | the notebook with all outputs |
| `results/results.json` | every experiment (configuration, per-epoch history, test/val metrics) |
| `cluster/` | scripts to run the whole notebook on the DISI SLURM cluster (`setup_env.sh`, `run_notebook.sbatch`) |
| `tools/make_submission.py` | checks the submission format and builds the zip |

Run on the cluster (already finished experiments in `results.json` are skipped with `IPCV_SKIP_DONE=1`):

```bash
sbatch --export=ALL,IPCV_SKIP_DONE=1 cluster/run_notebook.sbatch
```
