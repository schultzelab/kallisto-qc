#!/bin/bash

set -a

input=/input
output=/output
index=/index/index
gtffile=/index/annotations.gtf
tmpdir=$output/tmp
txgenesfile=$output/tx2genes.csv
samplelist=$output/samplelist.txt
outputkallisto=$output/kallisto

mkdir -p $tmpdir $outputkallisto

# first construct the list of files to process, along with their sampleids
# fastqfiles=$(find $input -name "*.fastq.gz" -type f)
paste -d',' \
      <(find $input -name "*.fastq.gz" -type f | eval $FILTERSAMPLEID ) \
      <(find $input -name "*.fastq.gz" -type f ) \
    | sort \
          > $samplelist

samples=$(cat $samplelist | cut -d',' -f1 | sort | uniq)

# should contain either "R1" or "R1 R2"
readends=$(cat $samplelist | cut -d',' -f2 | grep -o "_R[12]_" | tr -d '_' | sort | uniq)
# remove any newlines
readends="$(echo $readends)"

echo """
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

# check if a gtf file exists and generate the transcripts to genes
# file
if [ -f $gtffile ]; then
    echo "Generating a tx2genes.csv file from a gtf file"
    /scripts/gtf2tx2genes.sh $gtffile $txgenesfile
else
    echo "Could not find an index file at $gtffile"
    exit 1
fi


# generate a list of files in $input with a given sampleid and read end
function tagstofiles {
    sampleid="$1"
    R="$2"

    # filter out the files with a given sample id and R
    cat $samplelist \
        | grep "_${R}_[0-9]\{3\}.fastq.gz" \
        | awk -F',' -v sampleid="$sampleid" '{if($1==sampleid) print $2}'
}

export -f tagstofiles

function align {
    sampleid=$1
    outputk=$outputkallisto/$sampleid

    # if only R1 is present, the second tagstofiles will return an
    # empty list
    fastqs=$(paste \
                 <(tagstofiles $sampleid "R1") \
                 <(tagstofiles $sampleid "R2"))

    cmd="/scripts/run-kallisto.sh -t $THREADS -i \"$fastqs\" -x $index -o $outputk"

    # enable paired end in kallisto if necessary
    if [ "$(echo $readends)" == "R1 R2" ]; then
        cmd="$cmd -p"
    fi

    eval $cmd
}
export -f align

parallel --eta --will-cite -j $JOBS align {} ::: $samples

### Run MultiQC on kallisto results

# specifying the file list explicitly speeds up the process
logfiles=$tmpdir/logfilelist
find /output/kallisto -name "kallisto.log" > $logfiles
multiqc \
    -f \
    -o /output/multiqc-kallisto \
    --file-list $logfiles

### Aggregate results into one count table

# Run some R script to aggregate results from multiple samples into a
# single count table
Rscript /scripts/aggregate.R

rm -rf $tmpdir
