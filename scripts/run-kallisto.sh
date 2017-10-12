#!/bin/bash

inputs=$2
output=$1

echo $inputs
echo $output

# actual alignment
kallisto quant \
         -o $output \
         -i /index/index \
         -t 4 \
         --single \
         -l 75 \
         -s 1 \
         $inputs

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
