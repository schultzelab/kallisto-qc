#!/bin/bash

paired=""
threads="1"

function show_help(){
    echo """
    run-all -p if paired end
            -t [threads per job]
            -x [indexfile]
            -i [input files (in quatation marks)]
            -h
            [OPTIONS]
"""
}

while getopts "t:i:o:x:hp" opt; do
    case "$opt" in
        t)  threads="$OPTARG"
            ;;
        i)  input="$OPTARG"
            ;;
        x)  index="$OPTARG"
            ;;
        o)  output="$OPTARG"
            ;;
        p)  paired="true"
            ;;
        h|\?)
            show_help
            exit 0
            ;;
    esac
done

if [ -z $output ] || [ -z $index ] || [ -z "$input" ]; then
    echo "One or more required options are missing"
    show_help
    exit 1
fi

mkdir -p $output

# we align with both quant and pseoud because we need pseudocounts for
# the alignment statistics (not provided in the current kallisto
# version)

for mode in quant pseudo; do
    cmd="kallisto $mode -o $output -i $index -t $threads"
    if [ -n $paired ]; then
        cmd="$cmd"
    else
        cmd="$cmd --single -l 75 -s 1"
    fi

    echo "$input"

    cmd="$cmd $input"
    echo "$cmd"
    eval "$cmd"
done

# actual alignment
# kallisto quant \
#          -o $output \
#          -i /index/index \
#          -t 4 \
#          --single \
#          -l 75 \
#          -s 1 \
#          $inputs

# # we have to run kallisto for the second time to get the
# # pseudoalignment output
# kallisto pseudo \
#          -o $output \
#          -i /index/index \
#          -t 10 \
#          --single \
#          -l 75 \
#          -s 1 \
#          $inputs
