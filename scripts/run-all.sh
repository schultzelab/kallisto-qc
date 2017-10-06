#!/bin/bash

# 1. run fastqc

# 2. run kallisto
/scripts/run-kallisto.sh /input

# 3. run summary
/scripts/run-summary.sh /output
