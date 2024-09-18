
import re

rule smoove_lumpy:
    input:
        config['ref']['genome'],
        "bam_files/recal_{sample}.bam"
    output:
        "lumpy/{sample}/{sample}-smoove.vcf.gz" 
    conda:
        "../envs/smoove.yml"
    params:
        tempdir=config['tmpdir'],
    log:
        stderr="logs/smoove/smoove_lumpy_{sample}.log"
    shell:
        r"""
        mkdir -p lumpy/{wildcards.sample}
        smoove call --name {wildcards.sample} --fasta {input[0]} -p 1 --outdir lumpy/{wildcards.sample} {input[1]} 
        ls -sh {output}
        """

rule smoove_sort:
    input:
        "lumpy/{sample}/{sample}-smoove.vcf.gz"
    output:
        "lumpy/{sample}/sorted_lumpy_{sample}.vcf.gz"
    conda:
        "../envs/smoove.yml"
    params:
        tempdir=config['tmpdir']
    log:
        stderr="logs/lumpy/smoove_filter_{sample}.log"
    shell:
        r"""
        bcftools sort {input} -O z -o {output}
        tabix -p vcf {output};
        """


rule smoove_filter:
    input:
        config['ref']['bed'],
        "lumpy/{sample}/sorted_lumpy_{sample}.vcf.gz"
    output:
        "lumpy/lumpy_{sample}.vcf.gz"
    conda:
        "../envs/smoove.yml"
    params:
        tempdir=config['tmpdir']
    log:
        stderr="logs/lumpy/smoove_filter_{sample}.log"
    shell:
        r"""
        bcftools filter -R {input[0]} {input[1]} | bcftools filter -i 'SVTYPE="DEL"' | bgzip -c > {output};
        tabix -p vcf {output};
        """

