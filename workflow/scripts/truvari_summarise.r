#!/usr/bin/env Rscript

library(data.table)
library(dplyr)
library(jsonlite)
library(stringr)

SAMPLE = str_split_1(str_split_1(folder1, '_')[1] , '/')[2]
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


for (folder in snakemake@input){
    file = paste0(folder, "/summary.json")
    summary = fromJSON(file, flatten=TRUE)
    SVTYPE = c(SVTYPE, str_split_1(str_split_1(folder1, '_')[1] , '/')[3])
    CALLER = c(SVTYPE, str_split_1(folder, '_')[2])
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

write.table(df, paste0('truvari/', SAMPLE, '/summary.txt'), quote=F, sep="\t", col.names=T, row.names=F)

q(save="no")
