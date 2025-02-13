#!/bin/bash -l
#
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=8G

#change directory
cd /work/project/CASCAD/mnaji/sm_folder/workflow
#list available conda environment
conda info --envs
#activate conda
conda activate templatesnake

#execute snakefile
nohup snakemake -s Snakefile_call_all_SR_indiv --configfile config_call_all_SR_indiv.yaml --use-conda --profile genotoul --keep-going -p -c 32 &

#deactivate conda
conda deactivate

