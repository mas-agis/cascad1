
import re

rule manta_precomp:
    input:
        "bam_files/recal_{sample}.bam",
        config['ref']['genome']        
    output:
        ("manta/{sample}/runWorkflow.py") 
    conda:
        "../envs/manta.yml"
    params:
        tempdir=config['tmpdir'],
    log:
        stderr="logs/manta/manta_precomp_{sample}.log"
    shell:
        r"""
        mkdir -p manta/{wildcards.sample}
        configManta.py --normalBam {input[0]} --referenceFasta {input[1]} --runDir manta/{wildcards.sample}
        """


rule manta_comp:
    input:
        "manta/{sample}/runWorkflow.py"
    output:
        "manta/{sample}/results/variants/diploidSV.vcf.gz"
    conda:
        "../envs/manta.yml"
    params:
        tempdir=config['tmpdir']
    log:
        stderr="logs/manta/manta_comp_{sample}.log"
    shell:
        r"""
        python2.7 {input} -j 8 && ls -sh {output}
        """

rule manta_filter:
    input:
        config['ref']['bed'],
        "manta/{sample}/results/variants/diploidSV.vcf.gz"
    output: 
        "manta/{sample}.vcf.gz",
    conda:
        "../envs/manta.yml"
    params:
        tempdir=config['tmpdir']
    log:
        stderr="logs/manta/manta_filter_{sample}.log"
    shell:
        r"""
        bcftools filter -R {input[0]} {input[1]} | bgzip -c > {output};
        tabix -p vcf {output};
        """

