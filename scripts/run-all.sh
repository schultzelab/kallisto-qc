#!/bin/bash

set -a

jobs=$1

samples=$(for d in $(ls /input); do ls -1 /input/$d; done | sort | uniq)

function align {
    sample=$1
    fastqs=$(ls /input/*/$sample/*.fastq.gz)
    /scripts/run-kallisto.sh /output/kallisto/$sample/ "$fastqs"
}

export -f align
parallel --eta --will-cite -j $jobs align {} ::: $samples

Rscript /scripts/aggregate.R

# run fastqc
# /scripts/run-fastqc.sh
