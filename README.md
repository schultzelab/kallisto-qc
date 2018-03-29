# A simple RNA-seq pipeline #

## Input and output formats ##

You will need a kallisto index file, a tx2genes.csv file and the input
fastq files.  The output is a set of QC reports and a count table.

The internal scripts expect the following folder structure

- `/index/index`: the kallisto index file.
- `/index/annotations.gtf`: a annotations file used to convert
  transcript counts to gene counts.
- `/input/XXXXX`, `/input/YYYYY`, etc. the "runs" to be used in the
  alignment.  In practice these are the folders containing `fastq.gz`
  files that are interpreted as samples.  How exactly this
  interpretation is done depends on the `FILTERSAMPLEID` variable
  explained below.

## Parameters ##

All parameters are passed as environmental variables through the
`environment` field as in

    environment:
        - JOBS=4
        - THREADS=10

in the above example `JOBS` is the number of independent kallisto
processes, threads is the number of threads per kallisto process.

The pipeline extracts the sample id as the expression before the first
underscore in the base filename.  That is if the fastq files are named
as

    /input/run_171006/Sample_3651/3651_ATTCCT_L002_R1_001.fastq.gz

the sample id first extracts the file name
`3651_ATTCCT_L002_R1_001.fastq.gz` and then the first part before the
underscore, `3651`, becomes the sample id.  If the naming convention
differs from the one described above a user can specify any
pipe-compatible command via `FILTERSAMPLEID`, for example, the default
value of `FILTERSAMPLEID` is

    FILTERSAMPLEID="awk -F \"/\" '{print \$NF}'|cut -d'_' -f1"

*Important:* As per docker-compose specification, the `$` sign has to
be escaped with `$$` in the docker-compose.yml file.
