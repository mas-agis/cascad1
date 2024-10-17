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
conda activate templatesnake
```

###Dry-run to check whether pipeline is working and what jobs needed to run for completion of the pipeline
```
snakemake -s Snakefile_SV_genotyping --configfile config_SV_genotyping.yaml --use-conda --profile genotoul -p -n
```

### Running pipelines on the cluster (4 Snakefiles with corresponding config.yaml) - if run locally omit the '--profile genotoul
### The main snakemake process is send to backgroud by using 'nohup <COMMAND> &'
##1.Snakefile_longreads - Preprocessing, apply filter, and retain only DEL&INS for each individual SV vcf called from Cutesv, Pbsv, Sniffles

##2.Snakefile_SV_genotyping
```
nohup snakemake -s Snakefile_SV_genotyping --configfile config_SV_genotyping.yaml --use-conda --profile genotoul --keep-going -p -c 24 &
```
##3.Snakefile_truvari
```
nohup snakemake -s Snakefile_truvari --configfile config_truvari.yaml --use-conda --profile genotoul --keep-going -p -c 24 &
```
##4.Snakefile_breed_leave2_out
nohup snakemake -s Snakefile_breed_leave2_out --configfile config_breed_leave2_out.yaml --use-conda --profile genotoul --keep-going -p -c all &
```
##5.Snakefile_truvari_breed
snakemake -s Snakefile_truvari_breed --configfile config_breed_leave2_out.yaml --use-conda --keep-going -p -c 1
