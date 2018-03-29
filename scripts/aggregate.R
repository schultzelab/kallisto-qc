library(tximport)

tx2gene = read.csv("/output/tx2genes.csv")

basepath = "/output/kallisto"
samples = dir(path=basepath, full.names=FALSE, no..=TRUE)
files <- file.path(basepath, samples, "abundance.h5")
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

write.csv(ngenes.per.sample, file="/output/genecounts.csv")
write.csv(counts, file="/output/counts.csv")

library(ggplot2)
library(reshape2)

genecounts=read.csv("/output/genecounts.csv",row.names=1)
genecounts$Category = row.names(ngenes.per.sample)

pdf("/output/GeneCounts.pdf")
ggplot(melt(genecounts),aes(x=variable,y=value))+
    geom_point(aes(color=Category))+
    theme(axis.text.x = element_text(angle = 90, hjust = 1))
dev.off()
