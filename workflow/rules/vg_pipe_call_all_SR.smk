
import re

CHROM = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, "X"]

rule giraffe_all_mapping:
    input:
        vg_gbz=config['ref']['vg_gbz'], 
        vg_min=config['ref']['vg_min'],
        vg_dist=config['ref']['vg_dist'],
        fq1=get_fastq1, 
        fq2=get_fastq2
    output:
        temp("vg_all_map/{sample}.gam")
    conda:
        "../envs/vg.yml"
    log:
        stderr="logs/vg_all/giraffe_mapping_{sample}.log"
    threads: 32
    shell:
        r"""
        vg giraffe --gbz-name {input.vg_gbz} --minimizer-name {input.vg_min} --dist-name {input.vg_dist} -f {input.fq1} -f {input.fq2} --progress --threads {threads} --sample {wildcards.sample} > {output}
        """ 

rule giraffe_all_chunk:
    input:
        vg_xg=config['ref']['vg_xg'],
        vg_gam="vg_all_map/{sample}.gam"
    output:
        temp("vg_all_map/{sample}_{chr}_{chr}.gam")
    conda:
        "../envs/vg.yml"
    log:
        stderr="logs/vg_all/giraffe_chunk_{sample}_{chr}.log"
    shell:
        r"""
        vg chunk -x {input.vg_xg} -a {input.vg_gam} -C -p {wildcards.chr} -O pg --prefix vg_all_map/{wildcards.sample}_{wildcards.chr} && ls -sh {output}
        """

rule giraffe_all_chunk_vg:
    input:
        vg_xg=config['ref']['vg_xg']
    output:
        "vg_all_map/{chr}_{chr}.vg"
    conda:
        "../envs/vg.yml"
    log:
        stderr="logs/vg_all/giraffe_chunk_vg_{chr}.log"
    shell:
        r"""
        vg chunk -x {input.vg_xg} -C -p {wildcards.chr} > {output}
        """

rule giraffe_all_snarls:
    input:
        "vg_all_map/{chr}_{chr}.vg"
    output:
        "vg_all_map/pt{chr}.snarls"
    conda:
        "../envs/vg.yml"
    log:
        stderr="logs/vg_all/giraffe_snarls_{chr}.log"
    shell:
        r"""
        vg snarls {input} > {output}
        """

rule giraffe_all_pack:
    input:
        chr_vg="vg_all_map/{chr}_{chr}.vg",
        chr_gam="vg_all_map/{sample}_{chr}_{chr}.gam"
    output:
        temp("vg_all_map/{sample}_{chr}.pack")
    conda:
        "../envs/vg.yml"
    log:
        stderr="logs/vg_all/giraffe_pack_{sample}_{chr}.log"
    shell:
        r"""
        vg pack -x {input.chr_vg} -g {input.chr_gam} -Q 5 --threads 3 -o {output}
        """

rule giraffe_all_call: 
    input:
        chr_vg="vg_all_map/{chr}_{chr}.vg",
        chr_pack="vg_all_map/{sample}_{chr}.pack",
        chr_snarls="vg_all_map/pt{chr}.snarls"
    output:
        temp("vg_all_call/{sample}_{chr}.vcf")
    conda:
        "../envs/vg.yml"
    log:
        stderr="logs/vg_all/giraffe_call_{sample}_{chr}.log"
    shell:
        r"""
        vg call {input.chr_vg} -Aa -k {input.chr_pack} -r {input.chr_snarls} -s {wildcards.sample} --threads 3 > {output} 
        """

rule giraffe_all_concat:
    input:
        expand("vg_all_call/{{sample}}_{chr}.vcf", chr=CHROM)
    output:
        "vg_all_call/wg_{sample}.vcf.gz"
    conda:
        "../envs/mapping_min.yml"
    log:
        stderr="logs/vg_all/giraffe_concat_{sample}.log"
    params:
        tempdir="../results/tmp/"
    shell:
        r"""
        bcftools concat {input} --threads 3 | bcftools view -m2 -M2 --threads 3 | bcftools sort -T {params.tempdir} | bgzip -c > {output}
        """

rule giraffe_all_tabix:
    input:
        "vg_all_call/wg_{sample}.vcf.gz"
    output:
        "vg_all_call/wg_{sample}.vcf.gz.tbi"
    log:
        stderr="logs/vg_all/giraffe_tabix_{sample}.log"
    params:
        "-p vcf"
    wrapper:
        "v4.3.0/bio/tabix/index"
