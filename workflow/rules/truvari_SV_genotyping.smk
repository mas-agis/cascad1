
import re

samples = pd.read_table(config["samples"],
                        dtype={"sample": str}).set_index("sample", drop=False)


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
        stderr="logs/truvari/split_truth_set/{sample}.log"
    shell:
        r"""
        #DEL
        bcftools filter -i 'SVTYPE="DEL"' -O z -o {output[0]} {input}
        tabix -p vcf {output[0]}
        #INS
        bcftools filter -i 'SVTYPE="INS"' -O z -o {output[1]} {input}
        tabix -p vcf {output[1]}
        """

rule split_vg_comp:
    input: 
        "vg_call/wg_{sample}.vcf.gz" 
    output:
        temp("truvari/DEL_vg_{sample}.vcf.gz"),
        temp("truvari/INS_vg_{sample}.vcf.gz")
    conda:
        "../envs/truvari.yml"
    params:
        tempdir=config['tmpdir'],
    log:
        stderr="logs/truvari/split_vg_comp/{sample}.log"
    shell:
        r"""
        #DEL
        bcftools view {input} | grep -v '^#' | awk 'BEGIN{{FS=OFS="\t"}}(length($5)==1){{print $1,$2}}' > truvari/DEL_{wildcards.sample}.pos
        bcftools view -R truvari/DEL_{wildcards.sample}.pos {input} -O z -o {output[0]} 
        tabix -p vcf {output[0]} 
        rm truvari/DEL_{wildcards.sample}.pos
        #INS
        bcftools view {input} | grep -v '^#' | awk 'BEGIN{{FS=OFS="\t"}}(length($4)==1){{print $1,$2}}' > truvari/INS_{wildcards.sample}.pos
        bcftools view -R truvari/INS_{wildcards.sample}.pos {input} -O z -o {output[1]} 
        tabix -p vcf {output[1]} 
        rm truvari/INS_{wildcards.sample}.pos
        """

rule split_graphtyper:
    input:
        "graphtyper/graphtyper_{sample}.vcf.gz"        
    output:
        temp("truvari/DEL_graphtyper_{sample}.vcf.gz"),
        temp("truvari/INS_graphtyper_{sample}.vcf.gz")
    conda:
        "../envs/truvari.yml"
    params:
        tempdir=config['tmpdir'],
    log:
        stderr="logs/truvari/split_graphtyper/{sample}.log"
    shell:
        r"""
        #DEL
        bcftools filter -i 'SVTYPE="DEL"' {input} | bgzip -c > {output[0]} && tabix -p vcf {output[0]}
        #INS
        bcftools filter -i 'SVTYPE="INS"' {input} | bgzip -c > {output[1]} && tabix -p vcf {output[1]}
        """

rule split_paragraph:
    input:
        "paragraph/para_{sample}.vcf.gz"
    output:
        temp("truvari/DEL_paragraph_{sample}.vcf.gz"),
        temp("truvari/INS_paragraph_{sample}.vcf.gz")
    conda:
        "../envs/truvari.yml"
    params:
        tempdir=config['tmpdir'],
    log:
        stderr="logs/truvari/split_paragraph/{sample}.log"
    shell:
        r"""    
        #DEL
        bcftools filter -i 'SVTYPE="DEL"' {input} | bgzip -c > {output[0]} && tabix -p vcf {output[0]}
        #INS
        bcftools filter -i 'SVTYPE="INS"' {input} | bgzip -c > {output[1]} && tabix -p vcf {output[1]}
        """

rule split_manta:
    input:
        "manta/{sample}.vcf.gz"
    output:
        temp("truvari/DEL_manta_{sample}.vcf.gz"),
        temp("truvari/INS_manta_{sample}.vcf.gz")
    conda:
        "../envs/truvari.yml"
    params:
        tempdir=config['tmpdir'],
    log:
        stderr="logs/truvari/split_manta/{sample}.log"
    shell:
        r"""
        #DEL
        bcftools filter -i 'SVTYPE="DEL"' {input} | bgzip -c > {output[0]} && tabix -p vcf {output[0]}
        #INS
        bcftools filter -i 'SVTYPE="INS"' {input} | bgzip -c > {output[1]} && tabix -p vcf {output[1]}
        """

rule split_svtyper:
    input:
        "svtyper/noMis_{sample}_svtper.vcf.gz"
    output:
        temp("truvari/DEL_svtyper_{sample}.vcf.gz")
    conda:
        "../envs/truvari.yml"
    params:
        tempdir=config['tmpdir'],
    log:
        stderr="logs/truvari/split_svtyper/{sample}.log"
    shell:
        r"""
        #DEL
        bcftools filter -i 'SVTYPE="DEL"' {input} | bgzip -c > {output[0]} && tabix -p vcf {output[0]}
        """

rule truvari_filter_delly:
    input:
        config['ref']['bed'],
        "delly/pass_{sample}.vcf.gz"
    output:
        temp("truvari/DEL_delly_{sample}.vcf.gz")
    conda:
        "../envs/truvari.yml"
    params:
        tempdir=config['tmpdir'],
    log:
        stderr="logs/truvari/filter_delly/DEL_{sample}.log"
    shell:
        r"""
        bcftools filter -R {input[0]} {input[1]} | bgzip -c > {output};
        tabix -p vcf {output};
        """

rule truvari_bypass_lumpy:
    input:
        "lumpy/lumpy_{sample}.vcf.gz"
    output:
        temp("truvari/DEL_lumpy_{sample}.vcf.gz")
    conda:
        "../envs/truvari.yml"
    params:
        tempdir=config['tmpdir'],
    log:
        stderr="logs/truvari/filter_delly/DEL_{sample}.log"
    shell:
        r"""
        cp {input} {output} ;
        tabix -p vcf {output}
        """

rule truvari_bench_DEL:
    input:
        "truvari/truth_set/DEL_{sample}.vcf.gz",  #TruthSet_DEL
        "truvari/DEL_{tool}_{sample}.vcf.gz"            #comp_DEL
    output:
        directory("truvari/calc_DEL_{tool}_{sample}")
    conda:
        "../envs/truvari.yml"
    params:
        tempdir=config['tmpdir'],
    log:
        stderr="logs/truvari/bench/DEL_{sample}_{tool}.log"
    shell:
        r"""
        ##DEL
        truvari bench -b {input[0]} -c {input[1]} -o {output} -p 0 ;
        rm {input[1]}.tbi
        """

rule truvari_bench_INS:
    input:
        "truvari/truth_set/INS_{sample}.vcf.gz",  #TruthSet_INS
        "truvari/INS_{tool}_{sample}.vcf.gz"            #comp_INS
    output:
        directory("truvari/calc_INS_{tool}_{sample}")
    conda:
        "../envs/truvari.yml"
    params:
        tempdir=config['tmpdir'],
    log:
        stderr="logs/truvari/bench/INS_{sample}_{tool}.log"
    shell:
        r"""
        ##INS
        truvari bench -b {input[0]} -c {input[1]} -o {output} -p 0 ;
        rm {input[1]}.tbi
        """

rule truvari_summarise:
    input:
        expand("truvari/calc_DEL_{tool}_{sample}", sample=samples.index, tool=["vg", "graphtyper", "paragraph", "manta", "svtyper", "delly", "lumpy"]), 
        expand("truvari/calc_INS_{tool}_{sample}",  sample=samples.index, tool=["vg", "graphtyper", "paragraph", "manta"])
    output:
        "truvari/summary_SV_genotyping.txt"
    conda:
        "../envs/truvari.yml"
    params:
        tempdir=config['tmpdir'],
        r_script="../workflow/scripts/truvari_summarise.R"
    log:
        stderr="logs/truvari/summarise.log"
    shell: 
        r"""
        {params.r_script} {input}
        """  
           
#######################################################################
##PART of comparison between vg and paragraph SV genotype outputs
 
rule compare_vg_para_DEL:
    input: 
        "truvari/calc_DEL_vg_{sample}/tp-comp.vcf.gz",
        "truvari/calc_DEL_paragraph_{sample}/tp-comp.vcf.gz",
        "truvari/truth_set/DEL_{sample}.vcf.gz"
    output: 
        directory("truvari/compare_DEL_vg_para_{sample}")
    conda:
        "../envs/truvari.yml"
    params:
        tempdir=config['tmpdir'],
    log:
        stderr="logs/truvari/compare_vg_para/DEL_{sample}.log"
    shell:
        r"""
        ##DEL
        truvari bench -b {input[0]} -c {input[1]} -o {output} -p 0 ;
        """

rule compare_vg_para_DEL_inner:
    input:
        "truvari/compare_DEL_vg_para_{sample}",
        "truvari/truth_set/DEL_{sample}.vcf.gz"
    output:
        directory("truvari/exclusive_DEL_para_{sample}"),
        directory("truvari/exclusive_DEL_vg_{sample}"),
        directory("truvari/common_DEL_para_{sample}"),
        directory("truvari/common_DEL_vg_{sample}"),
    conda:
        "../envs/truvari.yml"
    params:
        tempdir=config['tmpdir'],
    log:
        stderr="logs/truvari/compare_vg_para_inner/DEL_{sample}.log"
    shell:
        r"""
        #exlusive para
        truvari bench -b {input[1]} -c {input[0]}/fp.vcf.gz -o {output[0]} -p 0 ;
        #exlusive vg
        truvari bench -b {input[1]} -c {input[0]}/fn.vcf.gz -o {output[1]} -p 0 ;
        #common para(common SV found also in vg)
        truvari bench -b {input[1]} -c {input[0]}/tp-comp.vcf.gz -o {output[2]} -p 0 ;
        #common vg(common SV found also in para)
        truvari bench -b {input[1]} -c {input[0]}/tp-base.vcf.gz -o {output[3]} -p 0 ;
        """

rule compare_vg_para_INS:
    input:
        "truvari/calc_INS_vg_{sample}/tp-comp.vcf.gz",
        "truvari/calc_INS_paragraph_{sample}/tp-comp.vcf.gz",
        "truvari/truth_set/INS_{sample}.vcf.gz"
    output:
        directory("truvari/compare_INS_vg_para_{sample}")
    conda:
        "../envs/truvari.yml"
    params:
        tempdir=config['tmpdir'],
    log:
        stderr="logs/truvari/compare_vg_para/INS_{sample}.log"
    shell:
        r"""
        ##INS
        truvari bench -b {input[0]} -c {input[1]} -o {output} -p 0 ;
        """

rule compare_vg_para_INS_inner:
    input:
        "truvari/compare_INS_vg_para_{sample}",
        "truvari/truth_set/INS_{sample}.vcf.gz"
    output:
        directory("truvari/exclusive_INS_para_{sample}"),
        directory("truvari/exclusive_INS_vg_{sample}"),
        directory("truvari/common_INS_para_{sample}"),
        directory("truvari/common_INS_vg_{sample}"),
    conda:
        "../envs/truvari.yml"
    params:
        tempdir=config['tmpdir'],
    log:
        stderr="logs/truvari/compare_vg_para_inner/INS_{sample}.log"
    shell:
        r"""
        #exlusive para
        truvari bench -b {input[1]} -c {input[0]}/fp.vcf.gz -o {output[0]} -p 0 ;
        #exlusive vg
        truvari bench -b {input[1]} -c {input[0]}/fn.vcf.gz -o {output[1]} -p 0 ;
        #common para(common SV found also in vg)
        truvari bench -b {input[1]} -c {input[0]}/tp-comp.vcf.gz -o {output[2]} -p 0 ;
        #common vg(common SV found also in para)
        truvari bench -b {input[1]} -c {input[0]}/tp-base.vcf.gz -o {output[3]} -p 0 ;
        """


rule truvari_summarise_compare_vg_para:
    input:
        expand("truvari/exclusive_DEL_para_{sample}", sample=samples.index),
        expand("truvari/exclusive_DEL_vg_{sample}", sample=samples.index),
        expand("truvari/common_DEL_para_{sample}", sample=samples.index),
        expand("truvari/common_DEL_vg_{sample}", sample=samples.index),
        expand("truvari/exclusive_INS_para_{sample}", sample=samples.index),
        expand("truvari/exclusive_INS_vg_{sample}", sample=samples.index),
        expand("truvari/common_INS_para_{sample}", sample=samples.index),
        expand("truvari/common_INS_vg_{sample}", sample=samples.index)
    output:
        "truvari/summary_compare_vg_para_SVgenotyping.txt"
    conda:
        "../envs/truvari.yml"
    params:
        tempdir=config['tmpdir'],
        r_script="../workflow/scripts/truvari_vg_para_summarise.R"
    log:
        stderr="logs/truvari/summarise_compare_vg_para.log"
    shell:
        r"""
        {params.r_script} {input}
        """



