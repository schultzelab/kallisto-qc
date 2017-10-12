#!/bin/bash

mkdir -p /output/fastqc

fastqc -o /output/fastqc \
       -t 10 \
       /input/*.fastq.gz
# fastqc /input/*.fastq.gz \
#        -o /output/fastqc \
