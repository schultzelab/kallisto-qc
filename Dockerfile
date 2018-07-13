FROM pwlb/rna-seq-pipeline-base:v0.1.0

COPY install /install
RUN Rscript /install/install.R

COPY scripts /scripts
COPY Snakefile /Snakefile

ENTRYPOINT ["bash","/scripts/run-all.sh"]
CMD [""]
