
import re
import os

samples = pd.read_table(config["samples1"],
                        dtype={"sample": str}).set_index("sample", drop=False)

rule jasmine_unzip:
    input:
        get_panel1
    output:
        "jasmine/{sample}_pbsv.vcf"        
    conda:
        "../envs/jasmine.yml"
    params:
        tempdir=config['tmpdir']
    log:
        stderr="logs/jasmine/unzip_{sample}.log"
    shell:
        r"""
        bgzip -d {input} > {output}
        """

rule jasmine_list_vcf:
    input:
        expand("jasmine/{sample}_pbsv.vcf", sample=samples.index)
    output:
        "jasmine/panel_list.txt"
    conda:
        "../envs/jasmine.yml"
    params:
        tempdir=config['tmpdir']
    log:
        stderr="logs/jasmine/panel_list.log"
    shell:
        r"""
        ls -1 {input} > {output}
        """

rule jasmine_merge:
    input:
        "jasmine/panel_list.txt", 
        config['ref']['genome']
    output:
        "jasmine/panel_SV.vcf"
    conda:
         "../envs/jasmine.yml"
    log:
        stderr="logs/jasmine/merge.log"
    params:
        tempdir=config['tmpdir']
    log:
        stderr="logs/jasmine/merge.log"
    shell:
        r"""
        jasmine file_list={input[0]} out_file={output} genome_file={input[1]} --ignore_strand --mutual_distance --allow_intrasample --output_genotypes
        """
