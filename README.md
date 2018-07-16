# A simple RNA-seq pipeline #

## Input and output formats ##

You will need a kallisto index file, an `annotations.gtf` file and the
input fastq files.  The output is a set of QC reports and a count
table.

The internal scripts expect the following folder structure

- `/index/index.kidx`: the kallisto index file.
- `/index/annotations.gtf`: a annotations file used to convert
  transcript counts to gene counts.
- `/input/XXXXX`, `/input/YYYYY`, etc. the "runs" to be used in the
  alignment.  In practice these are the folders containing `fastq.gz`
  files that are interpreted as samples.

## Advanced usage ##

You can specify a config file for the pipeline by mounting a
`/config.yaml` file (via e.g. `- my_config.yaml:/config.yaml:ro`).
The config can be used to select the samples to process and change the
kallisto parameters.  For example, to enable pseudobam generation, run
kallisto in single-end mode and process only samples `[4141,4136]` you
can use the following config file
```
kallisto:
  mode: "single"
  pseudobam: true
  threads: 10
  readlenght: 75
  readstd: 1
samples: [4141,4136]
```

The allowed values for the mode parameter are
`mode=["single","paired","auto"]`.  To run the alignment for all
samples use `samples=[]`.
