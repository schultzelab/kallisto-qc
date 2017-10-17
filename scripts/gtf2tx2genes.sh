#!/bin/bash

# a simple script to extract a tx2genes table from a gtf file

annotations=$1
output=$2

cat $annotations \
    | grep -e "\Wtranscript\W" \
    | cut -f 9 \
    | cut -d';' -f1-2 \
    | sed -e 's/gene_id //' -e 's/transcript_id //' -e 's/ //' \
    | awk -F';' 'BEGIN{print "TXNAME,GENEID"}; {sub(/\.[0-9]+/,"",$1); print $2 "," $1}' \
          > $output
