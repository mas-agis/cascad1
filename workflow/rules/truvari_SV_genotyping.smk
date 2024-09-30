
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
        temp("truvari/DEL_vg_{sample}.vcf.gz"),
        temp("truvari/INS_vg_{sample}.vcf.gz")
    conda:
        "../envs/truvari.yml"
    params:
        tempdir=config['tmpdir'],
    log:
        stderr="logs/truvari/split_vg_comp/{sample}.log"
    shell:
        r"""
        #DEL
        bcftools view {input} | grep -v '^#' | awk 'BEGIN{{FS=OFS="\t"}}(length($5)==1){{print $1,$2}}' > truvari/DEL_{wildcards.sample}.pos
        bcftools view -R truvari/DEL_{wildcards.sample}.pos {input} -O z -o {output[0]} 
        tabix -p vcf {output[0]} 
        rm truvari/DEL_{wildcards.sample}.pos
        #INS
        bcftools view {input} | grep -v '^#' | awk 'BEGIN{{FS=OFS="\t"}}(length($4)==1){{print $1,$2}}' > truvari/INS_{wildcards.sample}.pos
        bcftools view -R truvari/INS_{wildcards.sample}.pos {input} -O z -o {output[1]} 
        tabix -p vcf {output[1]} 
        rm truvari/INS_{wildcards.sample}.pos
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
        temp("truvari/DEL_paragraph_{sample}.vcf.gz"),
        temp("truvari/INS_paragraph_{sample}.vcf.gz")
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

rule truvari_filter_delly:
    input:
        config['ref']['bed'],
        "delly/pass_{sample}.vcf.gz"
    output:
        temp("truvari/DEL_delly_{sample}.vcf.gz")
    conda:
        "../envs/truvari.yml"
    params:
        tempdir=config['tmpdir'],
    log:
        stderr="logs/truvari/filter_delly/DEL_{sample}.log"
    shell:
        r"""
        bcftools filter -R {input[0]} {input[1]} | bgzip -c > {output};
        tabix -p vcf {output};
        """

rule truvari_bypass_lumpy:
    input:
        "lumpy/lumpy_{sample}.vcf.gz"
    output:
        temp("truvari/DEL_lumpy_{sample}.vcf.gz")
    conda:
        "../envs/truvari.yml"
    params:
        tempdir=config['tmpdir'],
    log:
        stderr="logs/truvari/filter_delly/DEL_{sample}.log"
    shell:
        r"""
        cp {input} {output} ;
        tabix -p vcf {output}
        """

rule truvari_bench_DEL:
    input:
        "truvari/truth_set/DEL_{sample}.vcf.gz",  #TruthSet_DEL
        "truvari/DEL_{tool}_{sample}.vcf.gz"            #comp_DEL
    output:
        directory("truvari/calc_DEL_{tool}_{sample}")
    conda:
        "../envs/truvari.yml"
    params:
        tempdir=config['tmpdir'],
    log:
        stderr="logs/truvari/bench/DEL_{sample}_{tool}.log"
    shell:
        r"""
        ##DEL
        truvari bench -b {input[0]} -c {input[1]} -o {output} -p 0 ;
        rm {input[1]}.tbi
        """

rule truvari_bench_INS:
    input:
        "truvari/truth_set/INS_{sample}.vcf.gz",  #TruthSet_INS
        "truvari/INS_{tool}_{sample}.vcf.gz"            #comp_INS
    output:
        directory("truvari/calc_INS_{tool}_{sample}")
    conda:
        "../envs/truvari.yml"
    params:
        tempdir=config['tmpdir'],
    log:
        stderr="logs/truvari/bench/INS_{sample}_{tool}.log"
    shell:
        r"""
        ##INS
        truvari bench -b {input[0]} -c {input[1]} -o {output} -p 0 ;
        rm {input[1]}.tbi
        """

rule truvari_summarise:
    input:
        "truvari/calc_DEL_{tool}_{sample}", 
        "truvari/calc_INS_{tool}_{sample}"
    output:
        "truvari/summary_{sample}.txt"
    conda:
        "../envs/truvari.yml"
    params:
        tempdir=config['tmpdir'],
    log:
        stderr="logs/truvari/summarise/{sample}.log"
    script: 
        "scripts/truvari_summarise.r"
            
#rule truvari_plot:
#    input:
#        summaries=expand("truvari/{sample}/summary.txt", sample=samples.index),
#        bam_depth=expand("../workflow/report/depth/{sample}.txt", sample=samples.index)
#    output:
#        "truvari/SV_genotyping.txt"
#    conda:
#        "../envs/truvari.yml"
#    params:
#        tempdir=config['tmpdir'],
#    log:
#        stderr="logs/truvari/plot.log"
#    script:
#        "scripts/truvari_plot.r"



