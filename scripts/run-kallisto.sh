#!/bin/bash

input=$1

# actual alignment
kallisto quant \
         -o /output \
         -i /index/index \
         -t 10 \
         --single \
         -l 200 \
         -s 20 \
         $input/*.fastq.gz

# we have to run kallisto for the second time to get the
# pseudoalignment output
kallisto pseudo \
         -o /output \
         -i /index/index \
         -t 10 \
         --single \
         -l 200 \
         -s 20 \
         $input/*.fastq.gz
