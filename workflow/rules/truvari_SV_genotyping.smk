
import re

rule split_truth_set:
    input:
        get_panel1
    output:
        "truvari/truth_set/DEL_{sample}.vcf.gz",
        "truvari/truth_set/INS_{sample}.vcf.gz" 
    conda:
        "../envs/truvari.yml"
    params:
        tempdir=config['tmpdir'],
    log:
        stderr="logs/truvari/truth_set/{sample}.log"
    shell:
        r"""
        #DEL
        bcftools filter -i 'SVTYPE="DEL"' -O z -o {output[0]} {input}
        tabix -p vcf {output[0]}
        #INS
        bcftools filter -i 'SVTYPE="INS"' -O z -o {output[1]} {input}
        tabix -p vcf {output[1]}
        """

rule get_pos_comp_vg:
    input: 
        "vg_call/wg_{sample}.vcf.gz" 
    output:
        temp("vg_call/DEL_{sample}.pos",
        temp("vg_call/INS_{sample}.pos"
    conda:
        "../envs/truvari.yml"
    params:
        tempdir=config['tmpdir'],
    log:
        stderr="logs/truvari/truth_set/{sample}.log"

         
  "graphtyper/graphtyper_{sample}.vcf.gz",
        "paragraph/para_{sample}.vcf.gz",
        "manta/{sample}.vcf.gz"

#list of output from SV genotyping - and the strategy
DEL-INS        expand("vg_call/wg_{sample}.vcf.gz.tbi", sample=samples.index),            #call vcf of SV genotypung on entire genome - vg_DEL.smk
 #1	bcftools view wg_Trio2-Offspring-CLR_giraffe_10x.vcf.gz | grep -v '^#' | awk '(length($4) == 1 ){print $0}' | wc -l #8760 asumsi DEL
 bcftools query -f '%CHROM\t%POS\t%REF\t%ALT\n' vcf_filtered_giraffe_called/wg_Trio2-Offspring-CLR_giraffe_10x.vcf.gz | grep -v '^#' | awk 'BEGIN{FS=OFS="\t"}(length($4)==1){print $1, $2}' | head
 #1	bcftools view wg_Trio2-Offspring-CLR_giraffe_10x.vcf.gz | grep -v '^#' | awk '(length($5) == 1 ){print $0}' | wc -l #9278 asumsi INS
 bcftools query -f '%CHROM\t%POS\t%REF\t%ALT\n' vcf_filtered_giraffe_called/wg_Trio2-Offspring-CLR_giraffe_10x.vcf.gz | grep -v '^#' | awk '(length($3)==1){print $1, $2}' | head
 #2     bcftools TYPE="deletion"  see TERMINOLOGY
 #2     bcftools TYPE="insertion" see TERMINOLOGY
DEL     keep SVTYPE=DEL   expand("svtyper/noMis_{sample}_svtper.vcf.gz",  sample=samples.index),       #call svtyper - remove missing genotype
DEL-INS SVTYPE=INS/DEL       expand("graphtyper/graphtyper_{sample}.vcf.gz", sample=samples.index),       #call graphtyper - not consistent result with previously on Trio2_offspring10x
DEL-INS SVTYPE=DEL/INS       expand("paragraph/para_{sample}.vcf.gz", sample=samples.index),              #call paragraph - re-run again
DEL     already DEL only     expand("delly/pass_{sample}.vcf.gz", sample=samples.index),                  #call delly
DEL-INS  SVTYPE=DEL/INS      expand("manta/{sample}.vcf.gz", sample=samples.index),                       #call manta
DEL     already DEL only     expand("lumpy/lumpy_{sample}.vcf.gz", sample=samples.index)]                 #call lumpy

