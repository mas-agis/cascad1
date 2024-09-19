
import re

rule graphtyper_genotype_sv:
    input: 
        config['ref']['genome'],
        get_panel1,
        "bam_files/recal_{sample}.bam",
        config['ref']['autX']
    output:
        temp("graphtyper/{sample}_okay.txt")
    conda:
        "../envs/graphtyper.yml"
    log:
        stderr="logs/graphtyper/genotype_sv_{sample}.log"
    shell:
        r"""
        mkdir -p graphtyper/temp_{wildcards.sample} 
        graphtyper genotype_sv {input[0]} {input[1]} --sam {input[2]} --output graphtyper/temp_{wildcards.sample}/ --threads 1 --verbose --region_file {input[3]} --verbose && touch {output}
        """

rule graphtyper_list_files:
    input:
        "graphtyper/{sample}_okay.txt"
    output:
        temp("graphtyper/{sample}_list_vcf.txt")
    conda:
        "../envs/graphtyper.yml"
    log:
        stderr="logs/graphtyper/list_files_{sample}.log"
    shell:
        r"""
        #list each chunk SV genotype vcf in aut+X in the folder
        echo {{1..29}} X | tr ' ' '\n' | while read chrom; do if [[ ! -d graphtyper/temp_{wildcards.sample}/${{chrom}} ]]; then continue; fi; find graphtyper/temp_{wildcards.sample}/${{chrom}} -name "*.vcf.gz" | sort; done > {output} 
        #remove the temp folder
        rm -r graphtyper/temp_{wildcards.sample}
        """

rule graphtyper_concat:
    input:
        "graphtyper/{sample}_list_vcf.txt"
    output:
        temp("graphtyper/concat_{sample}.vcf.gz")
    conda:
        "../envs/graphtyper.yml"
    params:
        tempdir=config['tmpdir']
    log:
        stderr="logs/graphtyper/concat_{sample}.log"
    shell:
        r"""
        bcftools concat --naive --file-list {input} | bcftools sort | bcftools filter -i 'SVLEN>50 & MaxAASR >= 0.5' | bcftools view -m2 -M2 | bgzip -c > {output}  #remove PASS filter
        tabix -p vcf {output} 
        """

rule graphtyper_filter:
    input:
        "graphtyper/concat_{sample}.vcf.gz"
    output:
        "graphtyper/graphtyper_{sample}.vcf.gz"
    conda:
        "../envs/graphtyper.yml"
    params:
        tempdir=config['tmpdir']
    log:
        stderr="logs/graphtyper/concat_{sample}.log"
    shell:
        r"""
        bcftools filter -i 'SVMODEL=="AGGREGATED"' {input} | bgzip -c > {output} 
        tabix -p vcf {output}
        """

