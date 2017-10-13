local({
  r <- getOption("repos")
  r["CRAN"] <- "https://cran.uni-muenster.de/"
  options(repos = r)
})

install.packages("ggplot2")
source("https://bioconductor.org/biocLite.R")
biocLite("tximport")
biocLite("rhdf5")
