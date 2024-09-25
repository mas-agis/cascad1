#!/usr/bin/env Rscript

library(data.table)
library(dplyr)
library(stringr)
library(ggplot2)

#For loop the truvari summaries 
df <- as.data.frame(matrix(ncol=12, nrow=0))
colnames(df) <- c('SAMPLE', 'SVTYPE', 'CALLER', 'BASE_count', 'COMP_count', 'TP_comp', 'FP', 'FN', 'PRECISION', 'RECALL', 'F1', 'GT_concord')
for (file in snakemake@input[[@summaries]]){
    temp <- fread(file, header=T)
    df <- rbind(df, temp)
}

#For loop read the average depth
sample = c()
bam_depth = c()
for (file1 in snakemake@input[[@bam_depth]]){
	sample = c(sample, gsub(".txt", "", file1))
	temp = fread(file1) %>% unlist()
	bam_depth = c(bam_depth, temp)
}
df1 = data.frame(SAMPLE=sample, BAM_DEPTH=bam_depth)

#INNER JOIN THE DF AND DF1
don = inner_join(df, df1, by="SAMPLE")

#GGPLOT

write.table(don, "truvari/SV_genotyping.svg", quote=F, sep="\t", col.names=T, row.names=F)

q(save="no")
