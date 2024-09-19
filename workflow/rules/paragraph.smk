
import re

rule paragraph_details:
    input:
        "bam_files/recal_{sample}.bam",
        "../workflow/report/bam_stats/{sample}.txt", 
        "../workflow/report/depth/{sample}.txt"
    output:
        "paragraph/details_{sample}.txt" 
    conda:
        "../envs/paragraph.yml"
    params:
        tempdir=config['tmpdir'],
        r_script="../workflow/scripts/paragraph_details.r"
    log:
        stderr="logs/paragraph/para_details_{sample}.log"
    shell:
        r"""
        #creating bash variable
        read_length=`grep "average length" {input[0]} | cut -f3 ` #average read length
        bam_depth=`cut -d ' ' -f1 {input[1]} ` #average read depth
        #execute R script to create details_sample.txt
        {params.r_script} {wildcards.sample} {input[0]} $bam_depth $read_length
        """


rule paragraph_genotypeSV:
    input:
        get_panel1,
        "paragraph/details_{sample}.txt",
        config['ref']['genome']
    output:
        "paragraph/temp_{sample}/genotypes.vcf.gz"
    conda:
        "../envs/paragraph.yml"
    params:
        tempdir=config['tmpdir']
    log:
        stderr="logs/paragraph/paragraph_genotypeSV_{sample}.log"
    shell:
        r"""
        multigrmpy.py -i {input[0]} -m {input[1]} -r {input[2]} -o paragraph/temp_{wildcards.sample} --threads 7 ;
        ls -sh {output}
        """

rule filter_paragraph:
    input:
        "paragraph/temp_{sample}/genotypes.vcf.gz"
    output:
        "paragraph/para_{sample}.vcf.gz"
    conda:
        "../envs/paragraph.yml"
    params:
        tempdir=config['tmpdir']
    log:
        stderr="logs/paragraph/filter_paragraph_{sample}.log"
    shell:
        r"""
        bcftools view -s {wildcards.sample} {input} | bcftools view -e 'GT="mis"' | bgzip -c > {output} && tabix -p vcf {output}
        """
 
