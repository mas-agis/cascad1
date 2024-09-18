
import re

rule delly_calling:
    input:
        config['ref']['genome'],
        "bam_files/recal_{sample}.bam"
    output:
        temp("delly/{sample}.vcf") 
    conda:
        "../envs/delly.yml"
    params:
        tempdir=config['tmpdir'],
    log:
        stderr="logs/delly/delly_calling_{sample}.log"
    shell:
        r"""
        delly call -g {input[0]} {input[1]} --svtype DEL > {output}
        """


rule delly_filter:
    input:
        "delly/{sample}.vcf"
    output:
        "delly/pass_{sample}.vcf.gz"
    conda:
        "../envs/delly.yml"
    params:
        tempdir=config['tmpdir']
    log:
        stderr="logs/delly/delly_filter_{sample}.log"
    shell:
        r"""
        bcftools filter -i 'FILTER=="PASS" && SVTYPE="DEL"' {input} -O z -o {output} ;
        tabix -p vcf {output}
        """
 
