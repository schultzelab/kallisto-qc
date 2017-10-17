#!/bin/bash

set -a

paired=""
jobs="1"
threads="1"
input="/input"
index="/index/index"
flat=""

function show_help(){
    echo """
    run-all -p if paired end
            -f if flat directory structure
            -j [kallisto jobs]
            -t [threads per job]
            -h
            [OPTIONS]
"""
}

while getopts "j:t:e:hpf" opt; do
    case "$opt" in
        t)  threads="$OPTARG"
            ;;
        j)  jobs="$OPTARG"
            ;;
        p)  paired="true"
            ;;
        f)  flat="true"
            ;;
        h|\?)
            show_help
            exit 0
            ;;
    esac
done

runs=$(ls -1 $input)

if [ -n $flat ]; then
    echo "Creating new directory structure for samples"
    inputnew="/inputnew"
    for r in $runs; do
        /scripts/samplestodirs.sh $input/$r $inputnew/$r
    done
    input=$inputnew
fi

# run fastqc
# todo parallelize
for run in $runs; do

    if [ -n "$paired" ]; then
        ends="R1 R2"
    else
        ends="R1"
    fi

    for R in $ends; do
        fastqs=$(find $input/$run -name "*$R*.fastq.gz")

        mergedfastq=/tmp/merged$R.fastq

        # take the first 10k reads from each file
        for fastq in $fastqs; do
            zcat $fastq | head -n 40000 >> $mergedfastq
        done
        mkdir -p /output/fastqc/$run/$R
        fastqc -o /output/fastqc/$run/$R \
               -t $threads \
               $mergedfastq

        rm -f $mergedfastq
    done
done

samples=$(for d in $(ls $input); do ls -1 $input/$d; done | sort | uniq)

function align {
    sample=$1
    outputk="/output/kallisto/$sample/"
    if [ -n $paired ]; then
        fastqs=$(paste <(ls $input/*/$sample/*R1*.fastq.gz) <(ls $input/*/$sample/*R2*.fastq.gz) | tr '\n' ' ')
        /scripts/run-kallisto.sh \
            -p \
            -t $threads \
            -i "$fastqs" \
            -x $index \
            -o $outputk
    else
        fastqs=$(ls $input/*/$sample/*.fastq.gz)
        /scripts/run-kallisto.sh \
            -t $threads \
            -i "$fastqs" \
            -x $index \
            -o $outputk
    fi
    nreads=$(cat $outputk/run_info.json | jq -r '.n_processed')
    naligned=$(cat $outputk/pseudoalignments.tsv \
                   | cut -f2 \
                   | paste -sd+ \
                   | bc )
    percentage=$(echo "scale=4; $naligned/$nreads" | bc)
    echo "$sample,$nreads,$naligned,$percentage" > $outputk/stats.csv
}

export -f align

parallel --eta --will-cite -j $jobs align {} ::: $samples
echo "sample,nreads,naligned,percentage" > /output/kallisto-stats.csv
find /output/kallisto -name 'stats.csv' | xargs cat  >> /output/kallisto-stats.csv

Rscript /scripts/aggregate.R
