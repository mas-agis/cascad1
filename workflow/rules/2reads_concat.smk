
import re

rule 2reads_concat_fastq1:
    input:
        get_R1_list
    output:
        "fastq/{sample}_R1.fastq.gz"
    conda:
        "../envs/mapping_min.yml"
    log:
        stderr="logs/2reads_concat_fastq/{sample}.log"
    shell:
        r"""
        cat {input} > {output}
        """

