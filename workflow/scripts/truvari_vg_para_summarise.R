#!/usr/bin/env Rscript

library(data.table)
library(dplyr)
library(jsonlite)
library(stringr)

#get input arguments
args = commandArgs(trailingOnly=TRUE)

##Truvari output section
SAMPLE = c()
SVTYPE = c()
CALLER = c()
BASE_count = c()
COMP_count = c()
TP_comp = c()
FP = c()
FN = c()
PRECISION = c()
RECALL = c()
F1 = c()
GT_concord = c()

#for (folder in snakemake@input){
for (folder in args){
    file = paste0(folder, "/summary.json")
    summary = fromJSON(file, flatten=TRUE)
    SAMPLE = c(SAMPLE, str_split_1(folder, '_')[4])
    SVTYPE = c(SVTYPE, str_split_1(folder, '_')[2])
    caller1 = str_split_1(str_split_1(folder, '/')[2], '_')[1]
    caller2 = str_split_1(str_split_1(folder, '/')[2], '_')[3]
    CALLER = c(CALLER, paste0(caller1, '_', caller2)) 
    BASE_count = c(BASE_count, summary$`base cnt`)
    COMP_count = c(COMP_count, summary$`comp cnt`)
    TP_comp = c(TP_comp, summary$`TP-comp`)
    FP = c(FP, summary$FP)
    FN = c(FN, summary$FN)
    PRECISION = c(PRECISION, summary$precision)
    RECALL = c(RECALL, summary$recall)
    F1 = c(F1, summary$f1)
    GT_concord = c(GT_concord, summary$gt_concordance)
}

df = data.frame(SAMPLE=SAMPLE, SVTYPE=SVTYPE, CALLER=CALLER, BASE_count=BASE_count, COMP_count=COMP_count, TP_comp=TP_comp, FP=FP, FN=FN, PRECISION=PRECISION, RECALL=RECALL, F1=F1, GT_concord=GT_concord)

write.table(df, "truvari/summary_compare_vg_para_SVgenotyping.txt", quote=F, sep="\t", col.names=T, row.names=F)

q(save="no")
