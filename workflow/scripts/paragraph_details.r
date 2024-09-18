#!/usr/bin/env Rscript

#Getting variables from direct arguments
args = commandArgs(trailingOnly=TRUE)
path <- getwd()
#create dataframe 
df <- data.frame(id=args[1], path=paste0(path, "/", args[2]), depth=round(as.numeric(args[3])), readZZlength=round(as.numeric(args[4])))
colnames(df) <- gsub("ZZ", " ", colnames(df))
#write out dataframe
write.table(df, paste0("paragraph/details_", args[1], ".txt"), sep="\t", quote=F, row.names=F, col.names=T)
q(save="no")
