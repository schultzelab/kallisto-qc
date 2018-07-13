#!/bin/bash

set -ex

cp /config.yaml /output

snakemake \
    --snakefile /Snakefile \
    --jobs $JOBS \
    --directory /output
