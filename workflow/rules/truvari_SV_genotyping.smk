
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
        stderr="logs/truvari/split_truth_set/{sample}.log"
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
        stderr="logs/truvari/split_graphtyper/{sample}.log"
    shell:
        r"""
        #DEL
        bcftools filter -i 'SVTYPE="DEL"' {input} | bgzip -c > {output[0]} && tabix -p vcf {output[0]}
        #INS
        bcftools filter -i 'SVTYPE="INS"' {input} | bgzip -c > {output[1]} && tabix -p vcf {output[1]}
        """

rule split_paragraph:
    input:
        "paragraph/para_{sample}.vcf.gz"
    output:
        temp("truvari/DEL_para_{sample}.vcf.gz"),
        temp("truvari/INS_para_{sample}.vcf.gz")
    conda:
        "../envs/truvari.yml"
    params:
        tempdir=config['tmpdir'],
    log:
        stderr="logs/truvari/split_paragraph/{sample}.log"
    shell:
        r"""    
        #DEL
        bcftools filter -i 'SVTYPE="DEL"' {input} | bgzip -c > {output[0]} && tabix -p vcf {output[0]}
        #INS
        bcftools filter -i 'SVTYPE="INS"' {input} | bgzip -c > {output[1]} && tabix -p vcf {output[1]}
        """

rule split_manta:
    input:
        "manta/{sample}.vcf.gz"
    output:
        temp("truvari/DEL_manta_{sample}.vcf.gz"),
        temp("truvari/INS_manta_{sample}.vcf.gz")
    conda:
        "../envs/truvari.yml"
    params:
        tempdir=config['tmpdir'],
    log:
        stderr="logs/truvari/split_manta/{sample}.log"
    shell:
        r"""
        #DEL
        bcftools filter -i 'SVTYPE="DEL"' {input} | bgzip -c > {output[0]} && tabix -p vcf {output[0]}
        #INS
        bcftools filter -i 'SVTYPE="INS"' {input} | bgzip -c > {output[1]} && tabix -p vcf {output[1]}
        """

rule split_svtyper:
    input:
        "svtyper/noMis_{sample}_svtper.vcf.gz"
    output:
        temp("truvari/DEL_svtyper_{sample}.vcf.gz")
    conda:
        "../envs/truvari.yml"
    params:
        tempdir=config['tmpdir'],
    log:
        stderr="logs/truvari/split_svtyper/{sample}.log"
    shell:
        r"""
        #DEL
        bcftools filter -i 'SVTYPE="DEL"' {input} | bgzip -c > {output[0]} && tabix -p vcf {output[0]}
        """

rule truvari_bench:
    input:
        "truvari/truth_set/DEL_{sample}.vcf.gz",  #TruthSet_DEL
        "truvari/truth_set/INS_{sample}.vcf.gz",  #TruthSet_INS
        "truvari/DEL_{sample}.vcf.gz",            #vg_DEL
        "truvari/DEL_graphtyper_{sample}.vcf.gz", #graphtyper_DEL
        "truvari/DEL_para_{sample}.vcf.gz",       #paragraph_DEL
        "truvari/DEL_manta_{sample}.vcf.gz",      #manta_DEL
        "truvari/DEL_svtyper_{sample}.vcf.gz",    #svtyper
        "delly/pass_{sample}.vcf.gz",             #delly_DEL
        "lumpy/lumpy_{sample}.vcf.gz",            #lumpy_DEL
        "truvari/INS_{sample}.vcf.gz",            #vg_INS
        "truvari/INS_graphtyper_{sample}.vcf.gz", #graphtyper_INS
        "truvari/INS_para_{sample}.vcf.gz",       #paragraph_INS
        "truvari/INS_manta_{sample}.vcf.gz"       #manta_INS        
    output:
        directory("truvari/{sample}/DEL_vg"),
        directory("truvari/{sample}/DEL_graphtyper"),
        directory("truvari/{sample}/DEL_paragraph"),
        directory("truvari/{sample}/DEL_manta"),
        directory("truvari/{sample}/DEL_svtyper"),
        directory("truvari/{sample}/DEL_delly"),
        directory("truvari/{sample}/DEL_lumpy"),
        directory("truvari/{sample}/INS_vg"),
        directory("truvari/{sample}/INS_graphtyper"),
        directory("truvari/{sample}/INS_paragraph"),
        directory("truvari/{sample}/INS_manta")
    conda:
        "../envs/truvari.yml"
    params:
        tempdir=config['tmpdir'],
    log:
        stderr="logs/truvari/bench/{sample}.log"
    shell:
        r"""
	##DEL
        truvari bench -b {input[0]} -c {input[2]} -o {output[0]} -p 0 ;
        truvari bench -b {input[0]} -c {input[3]} -o {output[1]} -p 0 ;
        truvari bench -b {input[0]} -c {input[4]} -o {output[2]} -p 0 ;
        truvari bench -b {input[0]} -c {input[5]} -o {output[3]} -p 0 ;
        truvari bench -b {input[0]} -c {input[6]} -o {output[4]} -p 0 ;
        truvari bench -b {input[0]} -c {input[7]} -o {output[5]} -p 0 ;
        truvari bench -b {input[0]} -c {input[8]} -o {output[6]} -p 0 ;
        ##INS
        truvari bench -b {input[1]} -c {input[9]} -o {output[7]} -p 0 ;
        truvari bench -b {input[1]} -c {input[10]} -o {output[8]} -p 0 ;
        truvari bench -b {input[1]} -c {input[11]} -o {output[9]} -p 0 ;
        truvari bench -b {input[1]} -c {input[12]} -o {output[10]} -p 0 ;
        """

rule truvari_summarise:
    input:
        "truvari/{sample}/DEL_vg",
        "truvari/{sample}/DEL_graphtyper",
        "truvari/{sample}/DEL_paragraph",
        "truvari/{sample}/DEL_manta",
        "truvari/{sample}/DEL_svtyper",
        "truvari/{sample}/DEL_delly",
        "truvari/{sample}/DEL_lumpy",
        "truvari/{sample}/INS_vg",
        "truvari/{sample}/INS_graphtyper",
        "truvari/{sample}/INS_paragraph",
        "truvari/{sample}/INS_manta"
    output:
        "truvari/{sample}/summary.txt"
    conda:
        "../envs/truvari.yml"
    params:
        tempdir=config['tmpdir'],
    log:
        stderr="logs/truvari/summarise/{sample}.log"
    script: 
        "scripts/truvari_summarise.r"
            
rule truvari_plot:
    input:
        summaries=expand("truvari/{sample}/summary.txt", sample=samples.index),
        bam_depth=expand("../workflow/report/depth/{sample}.txt", sample=samples.index)
    output:
        "truvari/SV_genotyping.svg"
    conda:
        "../envs/truvari.yml"
    params:
        tempdir=config['tmpdir'],
    log:
        stderr="logs/truvari/plot.log"
    script:
        "scripts/truvari_plot.r"




##list of output from SV genotyping - and the strategy
#DEL-INS        expand("vg_call/wg_{sample}.vcf.gz.tbi", sample=samples.index),            #call vcf of SV genotypung on entire genome - vg_DEL.smk
#DEL     keep SVTYPE=DEL   expand("svtyper/noMis_{sample}_svtper.vcf.gz",  sample=samples.index),       #call svtyper - remove missing genotype
#DEL-INS SVTYPE=INS/DEL       expand("graphtyper/graphtyper_{sample}.vcf.gz", sample=samples.index),       #call graphtyper - not consistent result with previously on Trio2_offspring10x
#DEL-INS SVTYPE=DEL/INS       expand("paragraph/para_{sample}.vcf.gz", sample=samples.index),              #call paragraph - re-run again
#DEL     already DEL only     expand("delly/pass_{sample}.vcf.gz", sample=samples.index),                  #call delly
#DEL-INS  SVTYPE=DEL/INS      expand("manta/{sample}.vcf.gz", sample=samples.index),                       #call manta
#DEL     already DEL only     expand("lumpy/lumpy_{sample}.vcf.gz", sample=samples.index)]                 #call lumpy

