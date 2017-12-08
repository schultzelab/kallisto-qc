#!/bin/bash

dir=$1
output=$2

mkdir -p $output

samples=$(ls -1 $dir | grep "fastq.gz"| awk '{split($0,a,"_"); print a[1]}' | sort | uniq)

for sample in $samples; do
    mkdir -p $output/$sample
    files=$(ls -1 $dir | grep "fastq.gz" | grep $sample)
    for f in $files; do
        ln -s $dir/$f $output/$sample/$f
    done
done
