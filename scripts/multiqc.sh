#!/bin/bash

# for kallisto
logfiles="/tmp/logfilelist"
find /output/kallisto -name "kallisto.log" > $logfiles
cat $logfiles

multiqc \
    -f \
    -o /output/multiqc-kallisto \
    --file-list $logfiles

# for fastqc
multiqc \
    -f \
    -o /output/multiqc-fastqc \
    /output/fastqc
