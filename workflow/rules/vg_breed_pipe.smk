
import re

CHROM = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, "X"]

rule construct_vg_breed:
    input:
        config['ref']['genome'],
        "../resources/{panel}.vcf.gz"
    params:
        outdir = "vg_breed_vg/"
    output:
        temp("vg_breed_vg/{panel}_pt{chr}.vg")
    conda:
        "../envs/vg.yml"
    log:
        stderr="logs/vg/construct_vg_{panel}_{chr}.log"
    shell:
        r"vg construct -C -R {wildcards.chr} -r {input[0]} -v {input[1]} -t 1 -m 32 -a > {output}"

rule sorting_DAG_breed:
    input:
        expand("vg_breed_vg/{{panel}}_pt{chr}.vg", chr=CHROM)
    output:
        temp("vg_breed_vg/{panel}_sorting_dag.txt") 
    conda:
        "../envs/vg.yml"
    log:
        stderr="logs/vg/sortingDAG_{panel}.log"
    shell:
        r"""
        vg ids -j {input} && echo "sorting DAG finish" > {output}
        """

rule indexing_xg_breed:
    input:
        list_vg=expand("vg_breed_vg/{{panel}}_pt{chr}.vg", chr=CHROM),
        test="vg_breed_vg/{panel}_sorting_dag.txt"
    output:
        "vg_breed_vg/{panel}_wg.xg"
    conda:
        "../envs/vg.yml"
    log:
        stderr="logs/vg/indexingXG_{panel}.log"
    shell:
        r"""
        ls {input.test};
        vg index -x {output} {input.list_vg} --progress -L
        """

rule convert_vg_breed:
    input:
        "vg_breed_vg/{panel}_wg.xg"
    output:
        "vg_breed_vg/{panel}_giraffe_wg.gfa"
    conda:
        "../envs/vg.yml"
    log:
        stderr="logs/vg/convertVG_{panel}.log"
    shell:
        r"vg convert --gfa-out {input} > {output}"

rule giraffe_autoindex_breed:
    input:
        "vg_breed_vg/{panel}_giraffe_wg.gfa"
    output:
        "vg_breed_vg/{panel}.giraffe.gbz",
        "vg_breed_vg/{panel}.min",
        "vg_breed_vg/{panel}.dist"
    conda:
        "../envs/vg.yml"
    log:
        stderr="logs/vg/giraffe_autoindex_{panel}.log"
    shell:
        r"""
        vg autoindex --workflow giraffe --gfa {input} --prefix vg_breed_vg/{wildcards.panel} && ls -sh {output[0]} && ls -sh {output[1]} && ls -sh {output[2]} 
        """

rule giraffe_mapping_breed:
    input:
        "vg_breed_vg/{panel}.giraffe.gbz",
        "vg_breed_vg/{panel}.min",
        "vg_breed_vg/{panel}.dist",
        get_fastq1,
        get_fastq2
    output:
        "vg_breed_map/{sample}_{panel}.gam"
    conda:
        "../envs/vg.yml"
    log:
        stderr="logs/vg/giraffe_mapping_{sample}_{panel}.log"
    shell:
        r"""
        vg giraffe --gbz-name {input[0]} --minimizer-name {input[1]} --dist-name {input[2]} -f {input[3]} -f {input[4]} --progress --threads 32 --sample {wildcards.sample}_{wildcards.panel} > {output}
        """ 

rule giraffe_chunk_breed:
    input:
        "vg_breed_vg/{panel}_wg.xg",
        "vg_breed_map/{sample}_{panel}.gam"
    output:
        temp("vg_breed_map/{sample}_{panel}_{chr}_{chr}.gam")
    conda:
        "../envs/vg.yml"
    log:
        stderr="logs/vg/giraffe_chunk_{sample}_{panel}_{chr}.log"
    shell:
        r"""
        vg chunk -x {input[0]} -a {input[1]} -C -p {wildcards.chr} -O pg --prefix vg_breed_map/{wildcards.sample}_{wildcards.panel}_{wildcards.chr} && ls -sh {output}
        """

rule giraffe_chunk_vg_breed:
    input:
        "vg_breed_vg/{panel}_wg.xg"
    output:
        temp("vg_breed_map/{sample}_{panel}_{chr}_{chr}.vg")
    conda:
        "../envs/vg.yml"
    log:
        stderr="logs/vg/giraffe_chunk_vg_{sample}_{panel}_{chr}.log"
    shell:
        r"""
        vg chunk -x {input[0]} -C -p {wildcards.chr} > {output}
        """

rule giraffe_snarls_breed:
    input:
        "vg_breed_map/{sample}_{panel}_{chr}_{chr}.vg"
    output:
        temp("vg_breed_map/{sample}_{panel}_pt{chr}.snarls")
    conda:
        "../envs/vg.yml"
    log:
        stderr="logs/vg/giraffe_snarls_{sample}_{panel}_{chr}.log"
    shell:
        r"""
        vg snarls {input} > {output}
        """

rule giraffe_pack_breed:
    input:
        "vg_breed_map/{sample}_{panel}_{chr}_{chr}.vg",
        "vg_breed_map/{sample}_{panel}_{chr}_{chr}.gam"
    output:
        temp("vg_breed_map/{sample}_{panel}_{chr}.pack")
    conda:
        "../envs/vg.yml"
    log:
        stderr="logs/vg/giraffe_pack_{sample}_{panel}_{chr}.log"
    shell:
        r"""
        vg pack -x {input[0]} -g {input[1]} -Q 5 --threads 3 -o {output}
        """

rule giraffe_call_breed: 
    input:
        "vg_breed_map/{sample}_{panel}_{chr}_{chr}.vg",
        "vg_breed_map/{sample}_{panel}_{chr}.pack",
        "vg_breed_map/{sample}_{panel}_pt{chr}.snarls"
    output:
        temp("vg_breed_call/{sample}_{panel}_{chr}.vcf")
    conda:
        "../envs/vg.yml"
    log:
        stderr="logs/vg/giraffe_call_{sample}_{panel}_{chr}.log"
    shell:
        r"""
        vg call {input[0]} -k {input[1]} -r {input[2]} -s {wildcards.sample}_{wildcards.panel} --threads 3 > {output} 
        """

rule giraffe_concat_breed:
    input:
        expand("vg_breed_call/{{sample}}_{{panel}}_{chr}.vcf", chr=CHROM)
    output:
        "vg_breed_call/wg_{sample}_{panel}.vcf.gz"
    conda:
        "../envs/mapping_min.yml"
    log:
        stderr="logs/vg/giraffe_concat_{sample}_{panel}.log"
    params:
        tempdir="../results/tmp/"
    shell:
        r"""
        bcftools concat {input} --threads 3 | bcftools view -m2 -M2 --threads 3 | bcftools sort -T {params.tempdir} | bgzip -c > {output}
        """

rule giraffe_tabix_breed:
    input:
        "vg_breed_call/wg_{sample}_{panel}.vcf.gz"
    output:
        "vg_breed_call/wg_{sample}_{panel}.vcf.gz.tbi"
    log:
        stderr="logs/vg/giraffe_tabix_{sample}_{panel}.log"
    params:
        "-p vcf"
    wrapper:
        "v4.3.0/bio/tabix/index"
