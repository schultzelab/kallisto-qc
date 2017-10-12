library(tximport)

tx2gene = read.csv("/index/tx2genes.csv")

basepath = "/output/kallisto"
samples = dir(path=basepath, full.names=FALSE, no..=TRUE)
files <- file.path(basepath, samples, "abundance.h5")
names(files) <- samples
txi.kallisto <- tximport(files, type="kallisto", tx2gene=tx2gene)
counts <- txi.kallisto$counts

ngenes=function(t) apply(counts>=t,2,sum)
thresholds = c(1,5,10,50,100)
ngenes.per.sample = t(sapply(thresholds,ngenes))
row.names(ngenes.per.sample) = thresholds

## filter the count table to only include the genes that are expressed
## in at least one sample
filter = apply(counts>=1,1,sum)>0
counts = counts[filter,]

write.csv(ngenes.per.sample, file="/output/genecounts.csv")
write.csv(counts, file="/output/counts.csv")
