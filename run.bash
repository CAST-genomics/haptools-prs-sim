#!/usr/bin/env bash
#PBS -V
#PBS -d .
#PBS -q home-gymrek
#PBS -j oe
#PBS -o /dev/null
#PBS -N run.snakemake
#PBS -l nodes=1:ppn=1
#PBS -l walltime=4:00:00
#PBS -W group_list=gymreklab-group
#PBS -A gymreklab-group


# An example bash script demonstrating how to run the entire snakemake pipeline
# This script creates two separate log files in the output dir:
# 	1) log - the basic snakemake log of completed rules

# Before running this snakemake pipeline, remember to complete the config file
# with the required input info.
# Also, make sure that this script is executed from the directory that it lives in!

mkdir -p "logs"

# clear leftover log files
echo ""> "logs/log"

# try to find and activate the snakemake conda env if we need it
if ! command -v 'snakemake' &>/dev/null && \
	command -v 'conda' &>/dev/null && \
   [ "$CONDA_DEFAULT_ENV" != "snakemake" ] && \
   conda info --envs | grep "$CONDA_ROOT/snakemake" &>/dev/null; then
        echo "Snakemake not detected. Attempting to switch to snakemake environment." >> "logs/qlog"
        eval "$(conda shell.bash hook)"
        conda activate snakemake
fi


# check: are we being executed from within qsub?
if [ "$ENVIRONMENT" = "BATCH" ]; then
    snakemake \
    --cluster "qsub -d . -V -q {resources.queue} -l walltime={resources.runtime} -l nodes=1:ppn={threads} -j oe -o /dev/null -W group_list=gymreklab-group -A gymreklab-group" \
    --default-resources 'runtime="00:30:00"' 'queue="condo"' \
    --latency-wait 60 \
    --use-conda \
    --conda-frontend mamba \
    --notemp \
    --rerun-trigger {mtime,params,input} \
    -k \
    -j 12 \
    -c 12 \
    "$@" &>>"logs/log"
else
    snakemake \
    --latency-wait 60 \
    --use-conda \
    --conda-frontend mamba \
    --notemp \
    --rerun-trigger {mtime,params,input} \
    -k \
    --cores all \
    "$@" &>>"logs/log"
fi

exit_code="$?"
if command -v 'slack' &>/dev/null; then
    if [ "$exit_code" -eq 0 ]; then
        slack "prsim finished successfully" &>/dev/null
    else
        slack "snakemake haptools-prs-sim job failed" &>/dev/null
        slack "$(tail -n4 "logs/log")" &>/dev/null
    fi
fi
exit "$exit_code"
