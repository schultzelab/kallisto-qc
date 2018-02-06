FROM pwlb/rna-seq-pipeline-base

COPY install /install
RUN Rscript /install/install.R

ENV FILTERSAMPLEID "gawk 'match(\$0,\"/([^_/]+)_[^/]*L[0-9]{3}_R[12]_[0-9]{3}.fastq.gz\",a) {print a[1]}'"
ENV THREADS 1
ENV JOBS 1

COPY scripts /scripts

ENTRYPOINT ["bash","/scripts/run-all.sh"]
CMD [""]
