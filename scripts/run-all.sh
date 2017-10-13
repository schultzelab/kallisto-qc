#!/bin/bash

# set -a

# jobs=$1

# run fastqc
# todo parallelize
# runs=$(ls -1 /input)
# for run in $runs; do
#     fastqs=$(find /input/$run -name "*.fastq.gz")

#     mergedfastq=/tmp/merged.fastq

#     # take the first 10k reads from each file
#     for fastq in $fastqs; do
#         zcat $fastq | head -n 40000 >> $mergedfastq
#     done

#     mkdir -p /output/fastqc/$run
#     fastqc -o /output/fastqc/$run \
#            -t 10 \
#            $mergedfastq

#     rm -f $mergedfastq
# done

# samples=$(for d in $(ls /input); do ls -1 /input/$d; done | sort | uniq)

# function align {
#     sample=$1
#     fastqs=$(ls /input/*/$sample/*.fastq.gz)
#     /scripts/run-kallisto.sh /output/kallisto/$sample/ "$fastqs"
# }

# export -f align
# parallel --eta --will-cite -j $jobs align {} ::: $samples

Rscript /scripts/aggregate.R
