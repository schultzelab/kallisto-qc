#!/bin/bash

output=/output/kallisto

nprocessed=$(cat $output/run_info.json | jq -r '.n_processed')
ntargets=$(cat $output/run_info.json | jq -r '.n_targets')

single=$(head -n $ntargets $output/pseudoalignments.tsv \
             | cut -f2 \
             | paste -sd+ \
             | bc )

multiple=$(tail -n +$ntargets $output/pseudoalignments.tsv \
               | cut -f2 \
               | paste -sd+ \
               | bc )

multiplealignmentrate=$(echo "scale=4; $multiple/$nprocessed" | bc)
singlealignmentrate=$(echo "scale=4; $single/$nprocessed" | bc)

cat $output/run_info.json \
    | jq -r ".n_single=$single" \
    | jq -r ".n_multiple=$multiple" \
    | jq -r ".rate_multiple=$multiplealignmentrate" \
    | jq -r ".rate_single=$singlealignmentrate" \
         > $output/run_info_2.json
mv $output/run_info{_2,}.json
