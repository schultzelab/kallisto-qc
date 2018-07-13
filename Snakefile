from pathlib import Path
from snakemake.shell import shell
from collections import namedtuple

filepattern = "/input/{run}/{sample}_S{sid}_L{lane}_R{read}_{num}.fastq.gz"

def get_file_data():
    return glob_wildcards(filepattern)


def data_to_dict(file_data):
    """converts a tuple of lists `(runs, samples, sids, lanes, reads,
nums)` into a list of named tuples so that you can iterate over the
tuples of the form `(run="run_1", sample="4414", sid="1", lane="002",
read="1")`.

    """
    Datum = namedtuple(
        "Datum",
        ["run", "sample", "sid", "lane", "read", "num"])
    data = []
    for datum in zip(*file_data):
        data.append(Datum(*datum))
    return data


def get_sample_files(wildcards, single=True):
    files = []
    for datum in data_to_dict(get_file_data()):
        if datum.sample == wildcards.sample:
            args = datum._asdict()
            r1 = filepattern.format(**{**args, "read": "1"})
            if single:
                files.append((r1,))
            else:
                r2 = filepattern.format(**{**args, "read": "2"})
                files.append((r1, r2))

    files = list(set(files))
    files = sum(map(list,files),[])
    return files


runs, samples, sids, lanes, reads, nums = get_file_data()

if set(reads) == set(["1","2"]):
    kallisto_single = False
elif set(reads) == set(["1"]):
    kallisto_single = True
else:
    raise Exception("Wrong read id")

pseudobam = False
kallisto_threads = 10


rule all:
    input:
        "multiqc/multiqc.html",
        "counts.csv",
        "genecounts.csv",
        "GeneCounts.pdf"

rule aggregate:
    input:
        abundance=list(set(expand("kallisto/{sample}/abundance.h5", sample=samples))),
        tx2genes="tx2genes.csv",
    output:
        counts="counts.csv",
        genecounts="genecounts.csv",
        genecounts_pdf="GeneCounts.pdf"
    log:
        "logs/aggregate.log"
    script:
        "/scripts/aggregate.R"

rule tx2genes:
    input:
        "/index/annotations.gtf"
    output:
        "tx2genes.csv"
    shell:
        """cat {input} \
        | grep -e "\Wtranscript\W" \
        | cut -f 9 \
        | cut -d';' -f1-2 \
        | sed -e 's/gene_id //' -e 's/transcript_id //' -e 's/ //' \
        | awk -F';' 'BEGIN{{print "TXNAME,GENEID"}}; {{print $2 "," $1}}' \
        > {output}"""

rule multiqc:
    input:
        expand("logs/kallisto/{sample}.log",zip,sample=samples)
    output:
        "multiqc/multiqc.html"
    log:
        "logs/multiqc.log"
    params:
        ""
    wrapper:
        "0.27.0/bio/multiqc"

rule kallisto_quant:
    input:
        reads=lambda wildcards: get_sample_files(wildcards,single=kallisto_single),
        index="/index/index.kidx"
    output:
        "kallisto/{sample}/abundance.h5",
        "kallisto/{sample}/abundance.tsv",
        "kallisto/{sample}/run_info.json"
    threads:
        kallisto_threads
    log:
        "logs/kallisto/{sample}.log"
    run:
        cmd = f"""kallisto quant -o kallisto/{wildcards.sample} -i {input.index} -t {kallisto_threads}"""

        if pseudobam:
            cmd += " --pseudobam --genomebam"
        if kallisto_single:
            cmd += " --single -l 75 -s1"
        cmd += f""" {input.reads}"""
        cmd += f""" &> {log}"""

        # print(cmd)
        shell(cmd)
