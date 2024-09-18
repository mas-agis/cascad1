
import re

rule 2reads_concat_fastq1:
    input:
        list1=get_R1_list
    output:
        "fastq/{sample}_R1.fastq.gz",
    conda:
        "../envs/mapping_min.yml"
    log:
        stderr="logs/2reads_concat_fastq/{sample}.log"
    shell:
        r"""
        cat {input.list1} > {output[0]}
        """

rule 2reads_concat_fastq2:
    input:
        list2=get_R2_list
    output:
        "fastq/{sample}_R2.fastq.gz",
    conda:
        "../envs/mapping_min.yml"
    log:
        stderr="logs/2reads_concat_fastq/{sample}.log"
    shell:
        r"""
        cat {input.list2} > {output[0]}
        """

rule 2reads_bwamap:
    input:
        config['ref']['genome'],
        "fastq/{sample}_R1.fastq.gz",
        "fastq/{sample}_R2.fastq.gz"
    output:
        temp("bam_files/{sample}.bam")
    conda:
        "../envs/mapping_min.yml"
    log:
        stderr="logs/2reads_bwmap/{sample}.log"
    shell:
        r"bwa mem -t 24 -R '@RG\tID:{wildcards.sample}\tPL:Illumina\tSM:{wildcards.sample}' {input} | samtools sort -@ 24 -m 1500M -n -T {wildcards.sample} -o {output} -O BAM"

rule 2reads_remove_dup:
    input: 
        "bam_files/{sample}.bam"
    output:
        temp("bam_files/reDup_{sample}.bam")
    conda:
        "../envs/mapping_min.yml"
    log:
        stderr="logs/2reads_bwmap/reDup_{sample}.log"
    shell:
        r"samtools fixmate -m -@ 24  {input} - | samtools rmdup -s -S - - | samtools sort -@ 24 -m 1500M -T {wildcards.sample} > {output} ; samtools index {output}"

rule 2reads_gatk_recalibration:
    input:
        config['ref']['genome'],
        config['ref']['known_sites'],
        "bam_files/reDup_{sample}.bam"
    output:
        temp("bam_files/{sample}.recal.table")
    conda:
        "../envs/mapping_min.yml"
    log:
        stderr="logs/2reads_gatk/recalibration_{sample}.log"
    shell:
        r"gatk BaseRecalibrator -R {input[0]} --known-sites {input[1]} -I {input[2]} -O {output}"

rule 2reads_gatk_apply_recalibration:
    input:
        config['ref']['genome'],
        "bam_files/reDup_{sample}.bam",
        "bam_files/{sample}.recal.table"
    output:
        "bam_files/recal_{sample}.bam"
    conda:
        "../envs/mapping_min.yml"
    log:
        stderr="logs/2reads_gatk/apply_recalibration_{sample}.log"
    shell:
        r"gatk ApplyBQSR -R {input[0]} -I {input[1]} -O {output} -bqsr {input[2]}"

rule 2reads_bam_depth:
    input:
        "bam_files/recal_{sample}.bam"
    output:
        "../workflow/report/depth/{sample}.txt"
    conda:
        "../envs/mapping_min.yml"
    log:
        stderr="logs/2reads_bwmap/depth_{sample}.log"
    shell:
        r"samtools depth {input} | awk '{{sum+=$3}} END{{print sum/NR}}' > {output}"

rule 2reads_bam_stats:
    input:
        "bam_files/recal_{sample}.bam"
    output: 
        "../workflow/report/bam_stats/{sample}.txt"
    conda:
        "../envs/mapping_min.yml"
    log:
        stderr="logs/2reads_bwmap/bam_stats_{sample}.log"
    shell:
        r"samtools stats {input} > {output}"

