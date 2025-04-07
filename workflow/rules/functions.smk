def get_fastq(wildcards): 
    """Get pair fastq files of given sample-unit."""
    fastqs = samples.loc[wildcards.sample, "reads"].split(",")
    return fastqs
def get_fastq1(wildcards):  
    """Get first-pair of fastq files of given sample-unit."""
    fastq1 = samples.loc[wildcards.sample, "reads"].split(",")[0]
    return fastq1
def get_fastq2(wildcards):  #first-pair fastq
    """Get second-pair of fastq files of given sample-unit."""
    fastq2 = samples.loc[wildcards.sample, "reads"].split(",")[1]
    return fastq2
def get_panel1(wildcards):
    """Get panel1 (PBSV) of given sample-unit - for SV_genotyping"""
    vcf = samples.loc[wildcards.sample, "SV_panel"]
    return vcf
def get_panel_breed(wildcards):
    """Get panel (PBSV) of given reference-sample - for breed_partial"""
    vcf = samples.loc[wildcards.sample, "SV_panel"]
    return vcf
def get_multi_fastq1(wildcards):
    """Get source of multi-files of splitted fq1"""
    source_SR = samples.loc[wildcards.sample, "multi_fq1"]
    source_SR = source_SR.replace(',', ' ')
    return source_SR
def get_multi_fastq2(wildcards):
    """Get source of multi-files of splitted fq2"""
    source_SR = samples.loc[wildcards.sample, "multi_fq2"]
    source_SR = source_SR.replace(',', ' ')
    return source_SR

