
import re

CHROM = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, "X"]

rule construct_vg:
    input:
        config['ref']['genome'],
        get_panel1
    params:
        outdir = "vg_vg/"
    output:
        temp("vg_vg/{sample}_pt{chr}.vg")
    conda:
        "../envs/vg.yml"
    log:
        stderr="logs/vg/construct_vg_{sample}_{chr}.log"
    shell:
        r"vg construct -C -R {wildcards.chr} -r {input[0]} -v {input[1]} -t 1 -m 32 -a > {output}"

rule sorting_DAG:
    input:
        expand("vg_vg/{{sample}}_pt{chr}.vg", chr=CHROM)
    output:
        temp("vg_vg/{sample}_sorting_dag.txt") 
    conda:
        "../envs/vg.yml"
    log:
        stderr="logs/vg/sortingDAG_{sample}.log"
    shell:
        r"""
        vg ids -j {input} && echo "sorting DAG finish" > {output}
        """

rule indexing_xg:
    input:
        list_vg=expand("vg_vg/{{sample}}_pt{chr}.vg", chr=CHROM),
        test="vg_vg/{sample}_sorting_dag.txt"
    output:
        "vg_vg/{sample}_wg.xg"
    conda:
        "../envs/vg.yml"
    log:
        stderr="logs/vg/indexingXG_{sample}.log"
    shell:
        r"""
        ls {input.test};
        vg index -x {output} {input.list_vg} --progress -L
        """

rule convert_vg:
    input:
        "vg_vg/{sample}_wg.xg"
    output:
        temp("vg_vg/{sample}_giraffe_wg.gfa")
    conda:
        "../envs/vg.yml"
    log:
        stderr="logs/vg/convertVG_{sample}.log"
    shell:
        r"vg convert --gfa-out {input} > {output}"

rule giraffe_autoindex:
    input:
        "vg_vg/{sample}_giraffe_wg.gfa"
    output:
        temp("vg_vg/{sample}.giraffe.gbz"),
        temp("vg_vg/{sample}.min"),
        temp("vg_vg/{sample}.dist")
    conda:
        "../envs/vg.yml"
    log:
        stderr="logs/vg/giraffe_autoindex_{sample}.log"
    shell:
        r"""
        vg autoindex --workflow giraffe --gfa {input} --prefix vg_vg/{wildcards.sample} && ls -sh {output[0]} && ls -sh {output[1]} && ls -sh {output[2]} 
        """

rule giraffe_mapping:
    input:
        "vg_vg/{sample}.giraffe.gbz",
        "vg_vg/{sample}.min",
        "vg_vg/{sample}.dist",
        get_fastq1,
        get_fastq2
    output:
        "vg_map/{sample}.gam"
    conda:
        "../envs/vg.yml"
    log:
        stderr="logs/vg/giraffe_mapping_{sample}.log"
    shell:
        r"""
        vg giraffe --gbz-name {input[0]} --minimizer-name {input[1]} --dist-name {input[2]} -f {input[3]} -f {input[4]} --progress --threads 32 --sample {wildcards.sample} > {output}
        """ 

rule giraffe_snarls:
    input:
        "vg_vg/{sample}_pt{chr}.vg"
    output:
        temp("vg_vg/{sample}_pt{chr}.snarls")
    conda:
        "../envs/vg.yml"
    log:
        stderr="logs/vg/giraffe_snarls_{sample}_{chr}.log"
    shell:
        r"""
        vg snarls {input} > {output} 
        """

rule giraffe_chunk:
    input:
        "vg_vg/{sample}_wg.xg",
        "vg_map/{sample}.gam"
    output:
        temp("vg_map/{sample}_{chr}_{chr}.gam")
    conda:
        "../envs/vg.yml"
    log:
        stderr="logs/vg/giraffe_chunk_{sample}_{chr}.log"
    shell:
        r"""
        vg chunk -x {input[0]} -a {input[1]} -C -p {wildcards.chr} -O vg --prefix vg_map/{wildcards.sample}_{wildcards.chr} && ls -sh {output}
        """

rule giraffe_pack:
    input:
        "vg_vg/{sample}_pt{chr}.vg",
        "vg_map/{sample}_{chr}_{chr}.gam"
    output:
        temp("vg_map/{sample}_{chr}.pack")
    conda:
        "../envs/vg.yml"
    log:
        stderr="logs/vg/giraffe_pack_{sample}_{chr}.log"
    shell:
        r"""
        vg pack -x {input[0]} -g {input[1]} -Q 5 --threads 3 -o {output}
        """

rule giraffe_call: 
    input:
        "vg_vg/{sample}_pt{chr}.vg",
        "vg_map/{sample}_{chr}.pack",
        "vg_vg/{sample}_pt{chr}.snarls"
    output:
        temp("vg_call/{sample}_{chr}.vcf")
    conda:
        "../envs/vg.yml"
    log:
        stderr="logs/vg/giraffe_call_{sample}_{chr}.log"
    shell:
        r"""
        vg call {input[0]} -k {input[1]} -r {input[2]} -s {wildcards.sample} --threads 3 > {output} 
        """
    
rule giraffe_concat:
    input:
        expand("vg_call/{{sample}}_{chr}.vcf", chr=CHROM)
    output:
        "vg_call/wg_{sample}.vcf.gz"
    conda:
        "../envs/mapping_min.yml"
    log:
        stderr="logs/vg/giraffe_concat_{sample}.log"
    params:
        tempdir="../results/tmp/"
    shell:
        r"""
        bcftools concat {input} --threads 3 | bcftools view -m2 -M2 --threads 3 | bcftools sort -T {params.tempdir} | bgzip -c > {output}
        """

rule giraffe_tabix:
    input:
        "vg_call/wg_{sample}.vcf.gz"
    output:
        "vg_call/wg_{sample}.vcf.gz.tbi"
    log:
        stderr="logs/vg/giraffe_tabix_{sample}.log"
    params:
        "-p vcf"
    wrapper:
        "v4.3.0/bio/tabix/index"
