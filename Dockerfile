FROM pwlb/rna-seq-pipeline-base:v0.1.1

COPY install /install
RUN Rscript /install/install.R

COPY scripts /scripts
COPY Snakefile /Snakefile
COPY config/config.yaml /config.yaml

ENTRYPOINT ["snakemake", "--snakefile", "/Snakefile", "--directory", "/output", "--jobs", "10"]
CMD [""]
