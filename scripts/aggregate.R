library(tximport)

tx2gene = read.csv(snakemake@input[["tx2genes"]])
files <- snakemake@input[["abundance"]]
samples <- sapply(files, function(x) strsplit(x,"/")[[1]][2])
names(files) <- samples

## get ensembl gene ids with corresponding transcript ids and transcript version
## this is not working because of the crazy dependencies in biomaRt

## library(biomaRt)
## ensembl <- useMart("ensembl",dataset=ensembl)
## bm <- getBM(attributes = c("ensembl_transcript_id", "transcript_version", "ensembl_gene_id"), mart = ensembl)
## tid_gid <- data.frame(transcript_id=paste(bm[,1], bm[,2], sep = "."), gene_id=bm[,3])

txi.kallisto <- tximport(files, type="kallisto", tx2gene=tx2gene)
counts <- txi.kallisto$counts

ngenes=function(t) apply(counts>=t,2,sum)
thresholds = c(1,5,10,50,100)
ngenes.per.sample = t(sapply(thresholds,ngenes))
row.names(ngenes.per.sample) = thresholds

## filter the count table to only include the genes that are expressed
## in at least one sample
filter = apply(counts>0,1,sum)>0
counts = counts[filter,]

write.csv(ngenes.per.sample, file=snakemake@output[["genecounts"]])
write.csv(counts, file=snakemake@output[["counts"]])

library(ggplot2)
library(reshape2)

genecounts=read.csv(snakemake@output[["genecounts"]],row.names=1)
genecounts$Category = row.names(ngenes.per.sample)

pdf(snakemake@output[["genecounts_pdf"]])
ggplot(melt(genecounts),aes(x=variable,y=value))+
    geom_point(aes(color=Category))+
    theme(axis.text.x = element_text(angle = 90, hjust = 1))
dev.off()
