
import re
import os

rule bgzip_raw:
    input:
        os.path.join(config['lr_dir'], "{sample_lr}_{caller}.vcf")
        
    output:
        temp("vcf_lr/raw_{sample_lr}_{caller}.vcf.gz")        
    conda:
        "../envs/mapping_min.yml"
    params:
        tempdir=config['tmpdir']
    log:
        stderr="logs/longreads/bgzip_raw_{sample_lr}_{caller}.log"
    shell:
        r"""
        bgzip -c {input} > {output}
        tabix -p vcf {output}
        """

rule filter_fix:
    input:
        config['ref']['bed'],
        "vcf_lr/raw_{sample_lr}_{caller}.vcf.gz"
    output:
        "vcf_lr/{sample_lr}_{caller}.vcf.gz"
    conda:
        "../envs/mapping_min.yml"
    params:
        tempdir=config['tmpdir']
    log:
        stderr="logs/longreads/filter_fix_{sample_lr}_{caller}.log"
    shell:
        r"""
        if [ pbsv = {wildcards.caller} ]
        then 
            bcftools view -R {input[0]} {input[1]} | bcftools filter -i 'SVTYPE="DEL" | SVTYPE="INS"' | bcftools filter -i '(SVLEN >= 50) | (SVLEN <= -50) ' | bcftools filter -i '(SVLEN <= 100000) | (SVLEN >= -100000)' | bcftools filter -i 'IMPRECISE !=1' | bgzip -c > {output}
        else
            bcftools view -R {input[0]} {input[1]} | bcftools filter -i 'SVTYPE="DEL" | SVTYPE="INS"' | bcftools filter -i '(SVLEN >= 50) | (SVLEN <= -50) ' | bcftools filter -i '(SVLEN <= 100000) | (SVLEN >= -100000)' | bcftools filter -i 'QUAL >= 20 && IMPRECISE !=1' | bgzip -c > {output}
        fi
        """

rule longreads_tabix:
    input:
        "vcf_lr/{sample_lr}_{caller}.vcf.gz"
    output:
        "vcf_lr/{sample_lr}_{caller}.vcf.gz.tbi"
    log:
        stderr="logs/longreads/tabix_{sample_lr}_{caller}.log"
    params:
        "-p vcf"
    wrapper:
        "v4.3.0/bio/tabix/index"

