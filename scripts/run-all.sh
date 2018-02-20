#!/bin/bash

set -a

input="/input"
output="/output"
index="/index/index"

runs=$(ls -1 $input)
samples=$(find $input -name "*.fastq.gz" -type f | eval "$FILTERSAMPLEID" |sort|uniq)
# readends=$(find $input -name "*.fastq.gz" -type f -printf "%f\n"|cut -d'_' -f4|sort|uniq)
# should contain either "R1" or "R1 R2"
readends=$(find $input -name "*.fastq.gz" -type f -printf "%f\n"|grep -o "_R[12]_"|tr -d '_'|sort|uniq)
# remove any newlines
readends="$(echo $readends)"

echo """
Processing runs
$runs

samples
$samples

read-ends
$readends
""" > $output/input.log
echo $samples > $output/sampleids.log

if [ -z "$samples" ]; then
    echo "Could not find any samples"
    exit 1
fi

if [ "$readends" != "R1" ] && [ "$readends" != "R1 R2" ]; then
    echo "Could not find proper read ends, see input.log for details"
    exit 1
fi


# generate a list of files in $input with a given runid, sampleid and R
function tagstofiles {
    runid="$1"
    sampleid="$2"
    R=$3

    files=$(mktemp)

    find $input/$runid -name "*_${R}_*.fastq.gz" > $files

    if [ "$sampleid" == "*" ]; then
        cat $files
        exit 0
    else
        paste -d',' \
              <(cat $files \
                    | eval $FILTERSAMPLEID ) \
              <(cat $files) \
            | awk -F',' -v sampleid="$sampleid" '{if($1==sampleid) print $2}' \
            | sort
    fi
}

export -f tagstofiles

for run in $runs; do
    for R in $readends; do
        fastqs=$(tagstofiles $run "*" $R)

        mergedfastq=/tmp/merged$R.fastq

        # take the first 10k reads from each file
        for fastq in $fastqs; do
            zcat $fastq | head -n 40000 >> $mergedfastq
        done
        mkdir -p $output/fastqc/$run/$R
        fastqc -o $output/fastqc/$run/$R \
               -t $THREADS \
               $mergedfastq

        rm -f $mergedfastq
    done
done

function align {
    sampleid=$1
    outputk="/output/kallisto/$sampleid/"

    fastqs=$(paste \
                 <(tagstofiles "*" $sampleid "R1") \
                 <(tagstofiles "*" $sampleid "R2"))

    cmd="/scripts/run-kallisto.sh -t $THREADS -i \"$fastqs\" -x $index -o $outputk"

    # enable paired end in kallisto if necessary
    if [ "$(echo $readends)" == "R1 R2" ]; then
        cmd="$cmd -p"
    fi

    eval $cmd
}
export -f align

parallel --eta --will-cite -j $JOBS align {} ::: $samples

/scripts/multiqc.sh

Rscript /scripts/aggregate.R
