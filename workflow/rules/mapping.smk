
import re


rule bwamap:
    input:
        config['ref']['genome'],
        get_fastq
    output:
        temp("bam_files/{sample}.bam")
    conda:
        "../envs/mapping_min.yml"
    log:
        stderr="logs/bwmap/{sample}.log"
    shell:
        r"bwa mem -t 24 -R '@RG\tID:{wildcards.sample}\tPL:Illumina\tSM:{wildcards.sample}' {input} | samtools sort -@ 24 -m 1500M -n -T {wildcards.sample} -o {output} -O BAM"

rule remove_dup:
    input: 
        "bam_files/{sample}.bam"
    output:
        temp("bam_files/reDup_{sample}.bam")
    conda:
        "../envs/mapping_min.yml"
    log:
        stderr="logs/bwmap/reDup_{sample}.log"
    shell:
        r"samtools fixmate -m -@ 24  {input} - | samtools rmdup -s -S - - | samtools sort -@ 24 -m 1500M -T {wildcards.sample} > {output} ; samtools index {output}"

rule gatk_recalibration:
    input:
        config['ref']['genome'],
        config['ref']['known_sites'],
        "bam_files/reDup_{sample}.bam"
    output:
        temp("bam_files/{sample}.recal.table")
    conda:
        "../envs/mapping_min.yml"
    log:
        stderr="logs/gatk/recalibration_{sample}.log"
    shell:
        r"gatk BaseRecalibrator -R {input[0]} --known-sites {input[1]} -I {input[2]} -O {output}"

rule gatk_apply_recalibration:
    input:
        config['ref']['genome'],
        "bam_files/reDup_{sample}.bam",
        "bam_files/{sample}.recal.table"
    output:
        "bam_files/recal_{sample}.bam"
    conda:
        "../envs/mapping_min.yml"
    log:
        stderr="logs/gatk/apply_recalibration_{sample}.log"
    shell:
        r"gatk ApplyBQSR -R {input[0]} -I {input[1]} -O {output} -bqsr {input[2]}"

rule bam_depth:
    input:
        "bam_files/recal_{sample}.bam"
    output:
        "../workflow/report/depth/{sample}.txt"
    conda:
        "../envs/mapping_min.yml"
    log:
        stderr="logs/bwmap/depth_{sample}.log"
    shell:
        r"samtools depth {input} | awk '{{sum+=$3}} END{{print sum/NR}}' > {output}"

rule bam_stats:
    input:
        "bam_files/recal_{sample}.bam"
    output: 
        "../workflow/report/bam_stats/{sample}.txt"
    conda:
        "../envs/mapping_min.yml"
    log:
        stderr="logs/bwmap/bam_stats_{sample}.log"
    shell:
        r"samtools stats {input} > {output}"

