# cascad1


### Create a conda env
```
mamba create  -c conda-forge -c bioconda -n templatesnake snakemake=8.12.0
mamba activate templatesnake
mamba install ...
pip install snakemake-executor-plugin-slurm
```
Once created use simply
```
mamba activate templatesnake
```


### Running the pipeline

#### on the cluster
##### dry-run
```
snakemake -s Snakefile_SV_genotyping --configfile config_SV_genotyping.yaml --use-conda --profile genotoul -p -n
```
##### real-run
```
snakemake -s Snakefile_SV_genotyping --configfile config_SV_genotyping.yaml --use-conda --profile genotoul --keep-going -p -c 24
```
##### real-run sending to background
```
nohup snakemake -s Snakefile_SV_genotyping --configfile config_SV_genotyping.yaml --use-conda --profile genotoul --keep-going -p -c 24 &
```


