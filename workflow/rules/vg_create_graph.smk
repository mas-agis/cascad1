
import re

CHROM = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, "X"]

rule create_graph_construct:
    input:
        config['ref']['genome'],
        "../resources/{panel}.vcf.gz"
    params:
        outdir = "vg_graph_vg/"
    output:
        temp("vg_graph_vg/{panel}_pt{chr}.vg")
    conda:
        "../envs/vg.yml"
    log:
        stderr="logs/vg/create_graph_construct_vg_{panel}_{chr}.log"
    shell:
        r"vg construct -C -R {wildcards.chr} -r {input[0]} -v {input[1]} -t 1 -m 32 -a > {output}"

rule create_graph_sorting_DAG:
    input:
        expand("vg_graph_vg/{{panel}}_pt{chr}.vg", chr=CHROM)
    output:
        temp("vg_graph_vg/{panel}_sorting_dag.txt") 
    conda:
        "../envs/vg.yml"
    log:
        stderr="logs/vg/create_graph_sortingDAG_{panel}.log"
    shell:
        r"""
        vg ids -j {input} && echo "sorting DAG finish" > {output}
        """

rule create_graph_indexing:
    input:
        list_vg=expand("vg_graph_vg/{{panel}}_pt{chr}.vg", chr=CHROM),
        test="vg_graph_vg/{panel}_sorting_dag.txt"
    output:
        "vg_graph_vg/{panel}_wg.xg"
    conda:
        "../envs/vg.yml"
    log:
        stderr="logs/vg/create_graph_indexingXG_{panel}.log"
    shell:
        r"""
        ls {input.test};
        vg index -x {output} {input.list_vg} --progress -L
        """

rule create_graph_convert_vg:
    input:
        "vg_graph_vg/{panel}_wg.xg"
    output:
        "vg_graph_vg/{panel}_giraffe_wg.gfa"
    conda:
        "../envs/vg.yml"
    log:
        stderr="logs/vg/create_graph_convertVG_{panel}.log"
    shell:
        r"vg convert --gfa-out {input} > {output}"

rule create_graph_giraffe_autoindex:
    input:
        "vg_graph_vg/{panel}_giraffe_wg.gfa"
    output:
        "vg_graph_vg/{panel}.giraffe.gbz",
        "vg_graph_vg/{panel}.min",
        "vg_graph_vg/{panel}.dist"
    conda:
        "../envs/vg.yml"
    log:
        stderr="logs/vg/create_graph_giraffe_autoindex_{panel}.log"
    shell:
        r"""
        vg autoindex --workflow giraffe --gfa {input} --prefix vg_graph_vg/{wildcards.panel} && ls -sh {output[0]} && ls -sh {output[1]} && ls -sh {output[2]} 
        """

