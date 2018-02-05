FROM pwlb/rna-seq-pipeline-base

COPY install /install
RUN Rscript /install/install.R

COPY scripts /scripts

ENTRYPOINT ["bash","/scripts/run-all.sh"]
CMD [""]
