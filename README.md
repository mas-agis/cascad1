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

### Dry-run 
Dry-run is used to check whether pipeline is working and what jobs needed to run for completion of the pipeline.\n
Here main input is the `Snakefile` and `config.yaml` respectively for each pipeline. \n
The `--use-conda` is applied as we provided the `.yaml` for each rule in the pipeline. 
```
snakemake -s Snakefile --configfile config.yaml --use-conda -p -n
```

### Running pipelines 
For running in the cluster (5 Snakefiles with corresponding config.yaml) - if run locally omit the '--profile genotoul.
The main snakemake process is sent to backgroud by using 'nohup <COMMAND> &'

#### 1.Snakefile_longreads 
Preprocessing, apply filter, and retain only DEL&INS for each individual SV vcf called from Cutesv, Pbsv, Sniffles
```
nohup snakemake -s Snakefile_longreads --configfile config_longreads.yaml --use-conda --profile genotoul --keep-going -p -c 24 &
```

#### 2.Snakefile_SV_genotyping
```
nohup snakemake -s Snakefile_SV_genotyping --configfile config_SV_genotyping.yaml --use-conda --profile genotoul --keep-going -p -c 24 &
```

#### 3.Snakefile_truvari
```
nohup snakemake -s Snakefile_truvari --configfile config_truvari.yaml --use-conda --profile genotoul --keep-going -p -c 24 &
```

#### 4.Snakefile_breed_leave2_out
```
nohup snakemake -s Snakefile_breed_leave2_out --configfile config_breed_leave2_out.yaml --use-conda --profile genotoul --keep-going -p -c 24 &
```

#### 5.Snakefile_truvari_breed
```
snakemake -s Snakefile_truvari_breed --configfile config_breed_leave2_out.yaml --use-conda --keep-going -p -c 1
```

#### 6.Snakefile_create_graph_panel
```
nohup snakemake -s Snakefile_create_graph_panel --configfile config_create_graph_panel.yaml --use-conda --profile genotoul --keep-going -p -c 24 &
```

#### 7.Snakefile_call_graph_panel
```
nohup snakemake -s Snakefile_call_graph_panel --configfile config_call_graph_panel.yaml --use-conda --profile genotoul --keep-going -p -c 24 &
```
#### 8.Snakefile_truvari_graph
```
snakemake -s Snakefile_truvari_graph --configfile config_call_graph_panel.yaml --use-conda --keep-going -p -c 1
```
#### 9.Snakefile_count_bubbles_vg
```
snakemake -s Snakefile_count_bubbles_vg --configfile config_call_graph_panel.yaml --use-conda --profile genotoul --keep-going -p -c 1
```
#### 10.Snakefile_call_all_SR_indiv
```
nohup snakemake -s Snakefile_call_all_SR_indiv --configfile config_call_all_SR_indiv.yaml --use-conda --profile genotoul --keep-going -p -c 32 &
