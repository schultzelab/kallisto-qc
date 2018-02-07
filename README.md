# A simple RNA-seq pipeline #

## Input and output formats ##

You will need a kallisto index file, a tx2genes.csv file and the input
fastq files.  The output is a set of QC reports and a count table.

The internal scripts expect the following folder structure

- `/index/index`: the kallisto index file
- `/index/tx2genes.csv`: a tx2genes.csv file that is used to convert
  the transcript names to gene names
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

The above parameters are self-explanatory, there is also a
`FILTERSAMPLEID`, which extracts the sample id from the filenames.
Consider a sample filename of the following form

    /input/run_171006/Sample_3651/3651_ATTCCT_L002_R1_001.fastq.gz

the exact form depends on how you mounted the directories in the
docker container and on the format of the files you are analyzing.

To extract the sample id from the directory name select `Sample_3651`
first and then the `3651` from that

    FILTERSAMPLEID=cut -d'/' -f4 | cut -d'_' -f2

Or you could just as easily select the first part of the base filename

    FILTERSAMPLEID=cut -d'/' -f5 | cut -d'_' -f1

By default the FILTERSAMPLEI selects exactly the part of the base
filename before `_ATTCCT`, that is `3651` and is a little bit more
complicated

    FILTERSAMPLEID=gawk '{match($$0,"/([^_/]+)_[^/]*L[0-9]{3}_R[12]_[0-9]{3}.fastq.gz",a); print a[1]}'

*Important:* As per docker-compose specification, the `$` sign has to
be escaped with `$$`.
