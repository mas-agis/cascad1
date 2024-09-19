
import re

rule bam_json:
    input:
        "bam_files/recal_{sample}.bam"
    output:
        temp("bam_files/recal_{sample}.bam.json")
    conda:
        "../envs/svtyper.yml"
    log:
        stderr="logs/svtyper/bam_json_{sample}.log"
    shell:
        r"svtyper -B {input} -l {output}"

rule modified_panel_vcf:
    input: 
        get_panel1
    output:
        temp("svtyper/modif_panel1_{sample}.vcf")
    conda:
        "../envs/svtyper.yml"
    log:
        stderr="logs/svtyper/modified_panel_vcf_{sample}.log"  
    shell:
        r"""
        bcftools view {input} | grep '^#' > {output}; 
        bcftools view {input} | grep -v '^#' |  sed 's/SVLEN/CIPOS\=-100,100\;CIEND\=-100,100\;CIPOS95=0,0\;CIEND95=0,0\;SVLEN/g' >> {output}
        """

rule svtyper_sso:
    input:
        "svtyper/modif_panel1_{sample}.vcf",
        "bam_files/recal_{sample}.bam",
        "bam_files/recal_{sample}.bam.json"
    output:
        temp("svtyper/{sample}_svtper.vcf.gz")
    conda:
        "../envs/svtyper.yml"
    log:
        stderr="logs/svtyper/svtyper_sso_{sample}.log"
    shell:
        r"svtyper-sso --batch_size 1000 --max_reads 1000000 -i {input[0]} -B {input[1]} -l {input[2]} --max_ci_dist 4 --split_weight 1 --disc_weight 1 | bgzip -c > {output}" 

rule tabix_svtyper_sso:
    input:
        "svtyper/{sample}_svtper.vcf.gz"
    output:
        temp("svtyper/{sample}_svtper.vcf.gz.tbi")
    log:
        stderr="logs/svtyper/tabix_svtyper_sso_{sample}.log"
    params:
        "-p vcf"
    wrapper:
        "v4.3.0/bio/tabix/index"    

rule svtyper_filter:
    input:
        "svtyper/{sample}_svtper.vcf.gz",
    output:
        "svtyper/noMis_{sample}_svtper.vcf.gz"
    conda:
        "../envs/svtyper.yml"
    log:
        stderr="logs/svtyper/svtyper_filter_{sample}.log"
    shell:
        r"""bcftools view -e 'GT="mis"' {input} | bgzip -c > {output} && tabix -p vcf {output} """

