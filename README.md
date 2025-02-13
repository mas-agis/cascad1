# Comprehensive Analysis of Structural Variants in Cattle Dataset (CASCAD)

This repository contains the commands and scripts to generate main dataset for *Comprehensive detection of structural variations in large dataset of long and short reads of 14 French cattle breeds, 2025, in press *. They are primarily in snakemake process listed with specified bio-conda environments for each rule execution. Of note, there are also several R scripts attached to summarise the output of analysis for producing the figures and tables. The analysis and corresponding inputs/outputs requirements are explained following the snakemake scripts.
 

### Create a conda env

We used the snakemake version 8.12.0 and created the environment via commands below
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

Dry-run is used to check whether pipeline is working and what jobs needed to run for completion of the pipeline.
Here main input is the `Snakefile` and `config.yaml` respectively for each pipeline. 
The `--use-conda` is applied as we provided the specific environment for each rule via respective `*.yaml` within. . 
```
snakemake -s Snakefile --configfile config.yaml --use-conda -p -n
```

### Running snakemake

We run the snakemake process in the Computing Cluster called genotoul. We set default resources and some specific rules requirements via '--profile genotoul' option. 
If run locally, omit this option. The main snakemake process is sent to backgroud by using 'nohup <COMMAND> &'. 

#### 1. Snakefile_longreads 
Here the pipeline is used for preprocessing, applying filter, and retaining only deletions and insertions SVtypes for each individual sequenced with long-reads where their SVs are called by Cutesv, Pbsv, and Sniffles before. 
In the `config_longreads.yaml`, we specified the path for files related to reference genome ARS_UCD1.2, snakemake's working directory and samples file (`samples_lr.tsv`). `samples_lr.tsv` is tab separated file with sample name and its respective long-reads sequencing technology.
In the `Snakefile_longreads`, we specified outputs of SV for each individual with respective SV caller. 
```
nohup snakemake -s Snakefile_longreads --configfile config_longreads.yaml --use-conda --profile genotoul --keep-going -p -c 24 &
```

#### 2.Snakefile_SV_genotyping
Here the pipeline is used for genotyping/recover known SV (base set) of each individual from their short-reads, respectively. We specified the samples file in `config_SV_genotyping.yaml`. `samples.tsv` is a with sample name in first column, path to paired fastq files in second column(separated by comma), and base set of known SV (called from long read by pbsv) in the third column used for genotyping. 
In the `Snakefile_SV_genotyping`, we load `.smk` modules for short reads mapping, respectively each genotyping SV tools, truvari benchmarking process and summary the outputs.  
```
nohup snakemake -s Snakefile_SV_genotyping --configfile config_SV_genotyping.yaml --use-conda --profile genotoul --keep-going -p -c 24 &
```

#### 3.Snakefile_truvari
Here the pipeline is used to further compared the genotyping of known SV by paragraph and vg toolkit from individual's short reads. Sample list is `samples.tsv`, the same for SV_genotyping comparison with all genotyping SV tools. 
```
nohup snakemake -s Snakefile_truvari --configfile config_truvari.yaml --use-conda --profile genotoul --keep-going -p -c 24 &
```

#### 4.Snakefile_breed_leave2_out
Here the pipeline is used for genotyping SV from different set of SV panels on 6 validation samples. In creating SV panels, we used reference samples differ from the validation ones. We incrementally adjust the number of samples representing breeds in the reference panel.
```
nohup snakemake -s Snakefile_breed_leave2_out --configfile config_breed_leave2_out.yaml --use-conda --profile genotoul --keep-going -p -c 24 &
```

#### 5.Snakefile_truvari_breed
Here is the pipeline to do truvari benchmarking of ouputted genotyping SV on difference reference panel for 6 validation samples as from the previous `Snakefile_breed_leave2_out`. 
```
nohup snakemake -s Snakefile_truvari_breed --configfile config_breed_leave2_out.yaml --use-conda --keep-going -p -c 1 &
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
```
#### 11.Snakefile_truvari_all
```
snakemake -s Snakefile_truvari_all --configfile config_truvari_all.yaml --use-conda --keep-going -p -c 1
```

