local({
  r <- getOption("repos")
  r["CRAN"] <- "http://ftp.gwdg.de/pub/misc/cran"
  options(repos = r)
})

install.packages("XML")
install.packages("RCurl")
install.packages("ggplot2")

source("https://bioconductor.org/biocLite.R")
biocLite("tximport")
biocLite("rhdf5")
## the dependencies here are fucked up for some reason
## biocLite("BiocGenerics")
## biocLite("AnnotationDbi")
## biocLite("biomaRt")
