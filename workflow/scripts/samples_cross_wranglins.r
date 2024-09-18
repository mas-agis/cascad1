#!/usr/bin/env Rscript

library(data.table)
library(dplyr)
library(stringr)
library(tidyr)
library(tidyverse)
#read the fastq_list file
df <- fread('fastq_list.txt', header=F)
#split the string of path to get the lab sample name
x <- str_split_fixed(df$V1, "/", 8)[,8]
lab_name <- str_split_fixed(x, "_",4 )[,1] 
#paste the lab name into the df file containing the path
df$lab_name <- lab_name
#get the code of R1/R2
read_sense <- lab_name <- str_split_fixed(x, "_",4 )[,4] 
#paste the read_sense into the df file containing the path
df$read_sense <- read_sense
#read the information of correspondance lab sample name and international identification
df1 <- fread('/home/mnaji/work/Project_A1P2-ApisGene-Bovin.1617/ind_CLR_fastq.txt', header=F)
#retain only fastq files for 154 cross individuals
df2 <- filter(df, lab_name %in% df1$V1)
#pivot wider df2 to column R1/R2 respectively containing list of reads
df3 <- pivot_wider(df2, names_from=read_sense, values_from=V1, values_fn = list)
df3$lab_name <- as.integer(df3$lab_name)
#inner join df3 containing the path and itnernational name in df1
df4 <- inner_join(df1, df3, by=c('V1'='lab_name')) 
#read the name of 179 long_reads
lr_sample <- fread('samples_lr.tsv', header=T)
lr_sample$V1 <- str_split_fixed(lr_sample$sample_lr, '-', 2)[,1]
#join lr_sample and df4 
lr_sample <- inner_join(lr_sample, df4, by=c('V1'='V5'))
#retain only necessary columns
lr_sample <- lr_sample[,c(1,2,4,5,6,7,9,10)]
#change col.names
colnames(lr_sample) <- c("sample_cross", "tech", "lab_name", "code", "sex", "breed", "R1_list", "R2_list")
##mutate R1_list and R2_list into strings 
cross_sample <- lr_sample %>% mutate(R1_list = map_chr(R1_list, toString))
cross_sample <- cross_sample %>% mutate(R2_list = map_chr(R2_list, toString))
##add info of sv panel
cross_sample$SV_panel <- paste0("/work/project/CASCAD/mnaji/sm_folder/results/vcf_lr/", cross_sample$sample_cross, "_pbsv.vcf.gz")
#write out the table 
write.table(cross_sample, 'samples_cross.tsv', sep='\t', quote=F, col.names=T, row.names=F)
