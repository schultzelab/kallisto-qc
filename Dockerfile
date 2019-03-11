FROM schultzelab/rna-seq-pipeline-base:v0.1.2

COPY install /install
RUN Rscript /install/install.R

COPY scripts /scripts
COPY Snakefile /Snakefile
COPY config/config.yaml /config.yaml

ENTRYPOINT ["snakemake", "--snakefile", "/Snakefile", "--directory", "/output", "--jobs", "10"]
CMD [""]
