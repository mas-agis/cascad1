
import re

CHROM = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, "X"]

rule giraffe_mapping_graph:
    input:
        "vg_graph_vg/{panel}.giraffe.gbz",
        "vg_graph_vg/{panel}.min",
        "vg_graph_vg/{panel}.dist",
        get_fastq1,
        get_fastq2
    output:
        "vg_graph_map/{sample}_{panel}.gam"
    conda:
        "../envs/vg.yml"
    log:
        stderr="logs/vg_graph/giraffe_mapping_{sample}_{panel}.log"
    shell:
        r"""
        vg giraffe --gbz-name {input[0]} --minimizer-name {input[1]} --dist-name {input[2]} -f {input[3]} -f {input[4]} --threads {threads} --progress --sample {wildcards.sample}_{wildcards.panel} > {output}
        """ 

rule giraffe_mapping_stats_graph:
    input:
        "vg_graph_map/{sample}_{panel}.gam"
    output:
        "vg_graph_stats/{sample}_{panel}.stats"
    conda:
        "../envs/vg.yml"
    log:
        stderr="logs/vg_graph/giraffe_mapping_stats_{sample}_{panel}.log"
    shell:
        r"""
        vg stats -a {input} --threads {threads} > {output}
        """

rule giraffe_chunk_graph:
    input:
        "vg_graph_vg/{panel}_wg.xg",
        "vg_graph_map/{sample}_{panel}.gam"
    output:
        temp("vg_graph_map/{sample}_{panel}_{chr}_{chr}.gam")
    conda:
        "../envs/vg.yml"
    log:
        stderr="logs/vg_graph/giraffe_chunk_{sample}_{panel}_{chr}.log"
    shell:
        r"""
        vg chunk -x {input[0]} -a {input[1]} -C -p {wildcards.chr} -O pg --prefix vg_graph_map/{wildcards.sample}_{wildcards.panel}_{wildcards.chr} && ls -sh {output}
        """

rule giraffe_chunk_vg_graph:
    input:
        "vg_graph_vg/{panel}_wg.xg"
    output:
        "vg_graph_map/{panel}_{chr}_{chr}.vg"
    conda:
        "../envs/vg.yml"
    log:
        stderr="logs/vg_graph/giraffe_chunk_vg_{panel}_{chr}.log"
    shell:
        r"""
        vg chunk -x {input[0]} -C -p {wildcards.chr} > {output}
        """

rule giraffe_snarls_graph:
    input:
        "vg_graph_map/{panel}_{chr}_{chr}.vg"
    output:
        "vg_graph_map/{panel}_pt{chr}.snarls"
    conda:
        "../envs/vg.yml"
    log:
        stderr="logs/vg_graph/giraffe_snarls_{panel}_{chr}.log"
    shell:
        r"""
        vg snarls {input} > {output}
        """

rule giraffe_pack_graph:
    input:
        "vg_graph_map/{panel}_{chr}_{chr}.vg",
        "vg_graph_map/{sample}_{panel}_{chr}_{chr}.gam"
    output:
        temp("vg_graph_map/{sample}_{panel}_{chr}.pack")
    conda:
        "../envs/vg.yml"
    log:
        stderr="logs/vg_graph/giraffe_pack_{sample}_{panel}_{chr}.log"
    shell:
        r"""
        vg pack -x {input[0]} -g {input[1]} -Q 5 --threads 3 -o {output}
        """

rule giraffe_call_graph: 
    input:
        "vg_graph_map/{panel}_{chr}_{chr}.vg",
        "vg_graph_map/{sample}_{panel}_{chr}.pack",
        "vg_graph_map/{panel}_pt{chr}.snarls"
    output:
        temp("vg_graph_call/{sample}_{panel}_{chr}.vcf")
    conda:
        "../envs/vg.yml"
    log:
        stderr="logs/vg_graph/giraffe_call_{sample}_{panel}_{chr}.log"
    shell:
        r"""
        vg call {input[0]} -k {input[1]} -r {input[2]} -s {wildcards.sample}_{wildcards.panel} --threads 3 > {output} 
        #vg call {input[0]} -a -k {input[1]} -r {input[2]} -s {wildcards.sample}_{wildcards.panel} --threads 3 > {output} #mod1 _ temporary test-calling all bubbles in the variation graph
        #vg call {input[0]} -A -k {input[1]} -r {input[2]} -s {wildcards.sample}_{wildcards.panel} --threads 3 > {output} #mod2 _ temporary test-calling all bubbles (even nested) in the variation graph
        """

rule giraffe_concat_graph:
    input:
        expand("vg_graph_call/{{sample}}_{{panel}}_{chr}.vcf", chr=CHROM)
    output:
        "vg_graph_call/wg_{sample}_{panel}.vcf.gz"
    conda:
        "../envs/mapping_min.yml"
    log:
        stderr="logs/vg_graph/giraffe_concat_{sample}_{panel}.log"
    params:
        tempdir="../results/tmp/"
    shell:
        r"""
        bcftools concat {input} --threads 3 | bcftools view -m2 -M2 --threads 3 | bcftools sort -T {params.tempdir} | bgzip -c > {output}
        """

rule giraffe_tabix_graph:
    input:
        "vg_graph_call/wg_{sample}_{panel}.vcf.gz"
    output:
        "vg_graph_call/wg_{sample}_{panel}.vcf.gz.tbi"
    log:
        stderr="logs/vg_graph/giraffe_tabix_{sample}_{panel}.log"
    params:
        "-p vcf"
    wrapper:
        "v4.3.0/bio/tabix/index"
