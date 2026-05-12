# QM/MM Umbrella Sampling Workflow

Generates [AMBER](https://ambermd.org/) input files and SLURM job scripts for
QM/MM potential-of-mean-force (PMF) calculations using umbrella sampling.

The workflow covers three sequential stages:

| Stage | Directory | Description |
|-------|-----------|-------------|
| 05 | `05_QMMM_restraint_free_simulations/` | Restraint-free QM/MM equilibration |
| 06 | `06_scan_umbrella_sampling/` | Restrained geometry scan — builds the starting structure for each window |
| 07 | `07_PMF_umbrella_sampling/` | PMF production runs (umbrella sampling windows) |

### Dependency graph

```
equil → scan[1] → scan[2] → … → scan[N]
            ↓         ↓               ↓
        pmf[1]    pmf[2]          pmf[N]
```

Each scan window depends on the previous one (sequential restarts).  
Each PMF window depends only on its own scan window.

---

## Prerequisites

- Python ≥ 3.6
- [PyYAML](https://pyyaml.org/) — `pip install pyyaml` or `conda install pyyaml`
- [AMBER](https://ambermd.org/) with QM/MM support (`sander.MPI`)
- SLURM workload manager

---

## Quick start

```bash
# 1. Edit the configuration file
vim config.yaml

# 2. Adapt HPC environment lines in the run templates (see below)
vim template_files/run_1_eq_template
vim template_files/run_2_scan_template
vim template_files/run_3_PMF_template

# 3. Generate all input files
python generate_inputs.py --config config.yaml

# 4. Preview the submission chain
python submit_jobs.py --config config.yaml --dry-run

# 5. Submit
python submit_jobs.py --config config.yaml
```

A self-contained bash alternative that combines generation and submission:

```bash
bash setup_launcher.sh
```

---

## Configuration (`config.yaml`)

All parameters live in a single file — the only file that needs editing per run.

| Key | Description |
|-----|-------------|
| `parm` | Path to the AMBER topology file (`.parm7`), relative to `config.yaml` |
| `geom` | Path to the starting restart file (`.rst7`), relative to `config.yaml` |
| `scheme` | Short label for SLURM job names (e.g. `"WT"`, `"D127N"`) |
| `qlevel` | QM theory level: `AM1`, `PM6`, `DFTB3`, … |
| `eecut` | Non-bonded cutoff for both QM and MM regions (Å) |
| `qmmask` | AMBER mask selecting the QM atoms (without surrounding quotes) |
| `qcharge` | Total charge of the QM region |
| `atom1`, `atom2`, `atom3` | Serial numbers of the three atoms defining the reaction coordinate |
| `coor0` | Starting value of the reaction coordinate (Å) — applied to window 1 |
| `windows` | Number of umbrella sampling windows |
| `scan_step` | Step size in Å per window (use a negative value for a reverse scan) |
| `force_equil` | Restraint force constant for equilibration (kcal/mol/Å²) |
| `force_scan` | Restraint force constant during the scan (kcal/mol/Å²) |
| `force_pmf` | Restraint force constant during PMF production (kcal/mol/Å²) |

### Reaction coordinate

The scanned coordinate is the antisymmetric stretch:

```
ξ = r(atom1–atom2) − r(atom2–atom3)
```

Suitable for proton-transfer or SN2 reactions where `atom2` is the transferring
heavy atom. `atom2` appears twice in the restraint (`iat = atom1, atom2, atom2, atom3`)
because AMBER's NMR restraint module uses two pairs to compute the difference.

---

## Adapting to your HPC environment

Each `template_files/run_*_template` file contains a clearly marked section
that must be adapted before use:

```bash
# ── Adapt to your HPC environment ─────────────────────────────────────────────
module load PrgEnv-gnu/8.5.0   # replace with your environment module
source ~/.local/amber.sh        # replace with your AMBER setup script

export MPICH_NO_BUFFER_ALIAS_CHECK=1      # Cray/MPICH — remove for other MPI
export SRUN_CPUS_PER_TASK=$SLURM_CPUS_PER_TASK   # Cray — remove for other MPI
# ──────────────────────────────────────────────────────────────────────────────
```

Also adjust `--ntasks` in the `#SBATCH` header to match your node configuration.

---

## File structure

```
QMMM_MD/
├── config.yaml                     # user configuration — edit this
├── generate_inputs.py              # generates input files from templates
├── submit_jobs.py                  # submits SLURM jobs with dependencies
├── setup_launcher.sh               # self-contained bash alternative
├── requirements.txt
└── template_files/
    ├── in_1_eq_free_template       # AMBER input — equilibration
    ├── in_2_restrained_template    # AMBER input — scan window
    ├── in_3_eq_template            # AMBER input — PMF equilibration
    ├── in_3_PMF_template           # AMBER input — PMF production
    ├── restr_template              # NMR flat-bottom restraint
    ├── run_1_eq_template           # SLURM job — equilibration
    ├── run_2_scan_template         # SLURM job — scan window
    └── run_3_PMF_template          # SLURM job — PMF window
```

Generated stage directories (`05_*/`, `06_*/`, `07_*/`) are excluded from
version control — regenerate them with `generate_inputs.py`.
