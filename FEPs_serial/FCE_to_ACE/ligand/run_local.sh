#!/bin/bash
# Sequential FEP run for a single GPU — no SLURM required.
#
# Usage:
#   bash run_local.sh                         # foreground
#   nohup bash run_local.sh > run.log 2>&1 &  # background
#
# Requires: AMBERHOME set, pmemd.cuda and cpptraj in $AMBERHOME/bin.

set -euo pipefail

SYSDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SYSDIR"

: "${AMBERHOME:?Please set AMBERHOME before running this script}"
AMBER="$AMBERHOME/bin/pmemd.cuda"
CPPTRAJ="$AMBERHOME/bin/cpptraj"

log() { echo "[$(date "+%Y-%m-%d %H:%M:%S")] $*"; }

# ---- Minimisation ------------------------------------------------
log "Minimisation"
$AMBER -i min.in -c ti.inpcrd -p ti.prmtop -O \
    -o min.out -inf min.info -e min.en -r min.rst -l min.log

# ---- Equilibration (CPU → GPU here for single-workstation use) ---
log "Equilibration"
$AMBER -i equil.in -c min.rst -p ti.prmtop -O \
    -o equil.out -inf equil.info -e equil.en \
    -r equil.rst -x equil.nc -l equil.log

# Extract 1 restart file(s) from the second half of the equil
# trajectory.  cpptraj appends .1 … .N to the output filename.
$CPPTRAJ <<_EOF
parm ti.prmtop
trajin equil.nc 200 200 1
trajout equil.rst7
_EOF

# ---- Replica 1 -------------------------------------------------
log "Replica 1/1"

log "  Window 5/9  lambda=0.50000"
cd "$SYSDIR/replica_1/5"
$AMBER -i ti_5.in -c ../../equil.rst7.1 -p ti.prmtop -O \
    -o ti001_5.out -inf ti001_5.info \
    -e ti001_5.en   -r ti001_5.rst \
    -x ti001_5.nc   -l ti001_5.log
$CPPTRAJ <<_EOF
parm ti.prmtop
trajin ti001_5.nc 500 500 1
trajout ti001_5_final.rst7
run
_EOF

log "  Window 4/9  lambda=0.33787"
cd "$SYSDIR/replica_1/4"
$AMBER -i ti_4.in -c ../5/ti001_5_final.rst7 -p ti.prmtop -O \
    -o ti001_4.out -inf ti001_4.info \
    -e ti001_4.en   -r ti001_4.rst \
    -x ti001_4.nc   -l ti001_4.log
$CPPTRAJ <<_EOF
parm ti.prmtop
trajin ti001_4.nc 500 500 1
trajout ti001_4_final.rst7
run
_EOF

log "  Window 3/9  lambda=0.19331"
cd "$SYSDIR/replica_1/3"
$AMBER -i ti_3.in -c ../4/ti001_4_final.rst7 -p ti.prmtop -O \
    -o ti001_3.out -inf ti001_3.info \
    -e ti001_3.en   -r ti001_3.rst \
    -x ti001_3.nc   -l ti001_3.log
$CPPTRAJ <<_EOF
parm ti.prmtop
trajin ti001_3.nc 500 500 1
trajout ti001_3_final.rst7
run
_EOF

log "  Window 2/9  lambda=0.08198"
cd "$SYSDIR/replica_1/2"
$AMBER -i ti_2.in -c ../3/ti001_3_final.rst7 -p ti.prmtop -O \
    -o ti001_2.out -inf ti001_2.info \
    -e ti001_2.en   -r ti001_2.rst \
    -x ti001_2.nc   -l ti001_2.log
$CPPTRAJ <<_EOF
parm ti.prmtop
trajin ti001_2.nc 500 500 1
trajout ti001_2_final.rst7
run
_EOF

log "  Window 1/9  lambda=0.01592"
cd "$SYSDIR/replica_1/1"
$AMBER -i ti_1.in -c ../2/ti001_2_final.rst7 -p ti.prmtop -O \
    -o ti001_1.out -inf ti001_1.info \
    -e ti001_1.en   -r ti001_1.rst \
    -x ti001_1.nc   -l ti001_1.log

log "  Window 6/9  lambda=0.66213"
cd "$SYSDIR/replica_1/6"
$AMBER -i ti_6.in -c ../5/ti001_5_final.rst7 -p ti.prmtop -O \
    -o ti001_6.out -inf ti001_6.info \
    -e ti001_6.en   -r ti001_6.rst \
    -x ti001_6.nc   -l ti001_6.log
$CPPTRAJ <<_EOF
parm ti.prmtop
trajin ti001_6.nc 500 500 1
trajout ti001_6_final.rst7
run
_EOF

log "  Window 7/9  lambda=0.80669"
cd "$SYSDIR/replica_1/7"
$AMBER -i ti_7.in -c ../6/ti001_6_final.rst7 -p ti.prmtop -O \
    -o ti001_7.out -inf ti001_7.info \
    -e ti001_7.en   -r ti001_7.rst \
    -x ti001_7.nc   -l ti001_7.log
$CPPTRAJ <<_EOF
parm ti.prmtop
trajin ti001_7.nc 500 500 1
trajout ti001_7_final.rst7
run
_EOF

log "  Window 8/9  lambda=0.91802"
cd "$SYSDIR/replica_1/8"
$AMBER -i ti_8.in -c ../7/ti001_7_final.rst7 -p ti.prmtop -O \
    -o ti001_8.out -inf ti001_8.info \
    -e ti001_8.en   -r ti001_8.rst \
    -x ti001_8.nc   -l ti001_8.log
$CPPTRAJ <<_EOF
parm ti.prmtop
trajin ti001_8.nc 500 500 1
trajout ti001_8_final.rst7
run
_EOF

log "  Window 9/9  lambda=0.98408"
cd "$SYSDIR/replica_1/9"
$AMBER -i ti_9.in -c ../8/ti001_8_final.rst7 -p ti.prmtop -O \
    -o ti001_9.out -inf ti001_9.info \
    -e ti001_9.en   -r ti001_9.rst \
    -x ti001_9.nc   -l ti001_9.log

log "All simulations complete."
