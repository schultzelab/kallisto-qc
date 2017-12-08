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
    run-all -j [kallisto jobs]
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
        h|\?)
            show_help
            exit 0
            ;;
    esac
done

runs=$(ls -1 $input)
samples=$(find $input -name "*.fastq.gz" -type f -printf "%f\n"|cut -d'_' -f1|sort|uniq)
readends=$(find $input -name "*.fastq.gz" -type f -printf "%f\n"|cut -d'_' -f4|sort|uniq)

echo """
Processing runs
$runs

samples
$samples

read-ends
$readends
""" > $output/input.log

# generate a name of the form $output/[RUNID]/[SAMPLEID]/[R{1,2}]/originalfilename.fastq.gz
function tagstofiles {
    basedir="$1"
    runid="$2"
    sampleid="$3"
    R=$4
    find $basedir/$runid -name "${sampleid}_*_${R}_*.fastq.gz" -type f|sort
}
export -f tagstofiles

for run in $runs; do
    for R in $readends; do
        fastqs=$(tagstofiles $input $run "*" $R)

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

function align {
    sampleid=$1
    outputk="/output/kallisto/$sampleid/"

    fastqs=$(paste \
                 <(tagstofiles $input "*" $sampleid "R1") \
                 <(tagstofiles $input "*" $sampleid "R2"))

    cmd="/scripts/run-kallisto.sh -t $threads -i \"$fastqs\" -x $index -o $outputk"

    # enable paired end in kallisto if necessary
    if [ "$(echo $readends)" == "R1 R2" ]; then
        cmd="$cmd -p"
    fi

    eval $cmd
}
export -f align

parallel --eta --will-cite -j $jobs align {} ::: $samples

/scripts/multiqc.sh

Rscript /scripts/aggregate.R
