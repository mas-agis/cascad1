
import re

rule split_truth_set:
    input:
        get_panel1
    output:
        "truvari/truth_set/DEL_{sample}.vcf.gz",
        "truvari/truth_set/INS_{sample}.vcf.gz" 
    conda:
        "../envs/truvari.yml"
    params:
        tempdir=config['tmpdir'],
    log:
        stderr="logs/truvari/truth_set/{sample}.log"
    shell:
        r"""
        #DEL
        bcftools filter -i 'SVTYPE="DEL"' -O z -o {output[0]} {input}
        tabix -p vcf {output[0]}
        #INS
        bcftools filter -i 'SVTYPE="INS"' -O z -o {output[1]} {input}
        tabix -p vcf {output[1]}
        """

rule split_vg_comp:
    input: 
        "vg_call/wg_{sample}.vcf.gz" 
    output:
        temp("truvari/DEL_{sample}.vcf.gz"),
        temp("truvari/INS_{sample}.vcf.gz")
    conda:
        "../envs/truvari.yml"
    params:
        tempdir=config['tmpdir'],
    log:
        stderr="logs/truvari/split_vg_comp/{sample}.log"
    shell:
        r"""
        #DEL
        bcftools view "vg_call/wg_{sample}.vcf.gz" | grep -v '^#' | awk 'BEGIN{FS=OFS="\t"}(length($5)==1){print $1,$2}' > truvari/DEL_{wildcards.sample}.pos
        bcftools view -R truvari/DEL_{wildcards.sample}.pos {input} -O z -o {output[0]} && tabix -p {output[0]} 
        rm -r truvari/DEL_{wildcards.sample}.pos
        #INS
        bcftools view "vg_call/wg_{sample}.vcf.gz" | grep -v '^#' | awk 'BEGIN{FS=OFS="\t"}(length($4)==1){print $1,$2}' > truvari/INS_{wildcards.sample}.pos
        bcftools view -R truvari/INS_{wildcards.sample}.pos {input} -O z -o {output[1]} && tabix -p {output[1]} 
        rm -r truvari/INS_{wildcards.sample}.pos
        """

rule split_graphtyper:
    input:
        "graphtyper/graphtyper_{sample}.vcf.gz"        
    output:
        temp("truvari/DEL_graphtyper_{sample}.vcf.gz"),
        temp("truvari/INS_graphtyper_{sample}.vcf.gz")
    conda:
        "../envs/truvari.yml"
    params:
        tempdir=config['tmpdir'],
    log:
        stderr="logs/truvari/get_vg_pos/{sample}.log"
    shell:
        r"""
        #DEL
        bcftools filter -i 'SVTYPE="DEL"' {input} | bgzip -c > {output[0]} && tabix -p vcf {output[0]}
        #INS
        bcftools filter -i 'SVTYPE="INS"' {input} | bgzip -c > {output[1]} && tabix -p vcf {output[1]}
        """

rule split_paragraph:


rule truvari_bench:
    input:
        "truvari/truth_set/DEL_{sample}.vcf.gz",
        "truvari/truth_set/INS_{sample}.vcf.gz",
        "truvari/DEL_{sample}.vcf.gz",            #vg_DEL
        "svtyper/noMis_{sample}_svtper.vcf.gz",   #svtyper
        "truvari/DEL_graphtyper_{sample}.vcf.gz", #graphtyper_DEL
        "truvari/INS_{sample}.vcf.gz",            #vg_INS
        "truvari/INS_graphtyper_{sample}.vcf.gz",  #graphtyper_INS
        
     output:
        "truvari/Bench_DEL_vg_{sample}.json",
        "truvari/Bench_INS_vg_{sample}.json"
    conda:
        "../envs/truvari.yml"
    params:
        tempdir=config['tmpdir'],
    log:
        stderr="logs/truvari/bench/{sample}.log"
    shell:
        r"""
	##DEL
        #vg
        truvari bench -b {input[0]} -c {input[]} -o temp_truvari_{wildcards.sample} -p 0 && mv temp_truvari_{wildcards.sample}/summary.json {output[]} && rm -r temp_truvari_{wildcards.sample}
        ##INS
        truvari bench -b {input[0]} -c {input[]} -o temp_truvari_{wildcards.sample} -p 0 && mv temp_truvari_{wildcards.sample}/summary.json {output[]} && rm -r temp_truvari_{wildcards.sample}

  "graphtyper/graphtyper_{sample}.vcf.gz",
        "paragraph/para_{sample}.vcf.gz",
        "manta/{sample}.vcf.gz"

##list of output from SV genotyping - and the strategy
#DEL-INS        expand("vg_call/wg_{sample}.vcf.gz.tbi", sample=samples.index),            #call vcf of SV genotypung on entire genome - vg_DEL.smk
#DEL     keep SVTYPE=DEL   expand("svtyper/noMis_{sample}_svtper.vcf.gz",  sample=samples.index),       #call svtyper - remove missing genotype
#DEL-INS SVTYPE=INS/DEL       expand("graphtyper/graphtyper_{sample}.vcf.gz", sample=samples.index),       #call graphtyper - not consistent result with previously on Trio2_offspring10x
DEL-INS SVTYPE=DEL/INS       expand("paragraph/para_{sample}.vcf.gz", sample=samples.index),              #call paragraph - re-run again
DEL     already DEL only     expand("delly/pass_{sample}.vcf.gz", sample=samples.index),                  #call delly
DEL-INS  SVTYPE=DEL/INS      expand("manta/{sample}.vcf.gz", sample=samples.index),                       #call manta
DEL     already DEL only     expand("lumpy/lumpy_{sample}.vcf.gz", sample=samples.index)]                 #call lumpy

