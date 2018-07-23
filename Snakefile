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


def get_sample_files(sample, mode):
    """Returns a list of fastq.gz files associated to a given `sample`. if
single==True the list contains only R1, if single==False the list
contains R1 and R2 paired by base filename (so [fileA_R1, fileA_R2,
fileB_R1, fileB_R2, ...].

    """

    files = []
    for datum in data_to_dict(get_file_data()):
        if datum.sample == sample:
            args = datum._asdict()
            r1 = filepattern.format(**{**args, "read": "1"})
            if mode=="single":
                files.append((r1,))
            else:
                r2 = filepattern.format(**{**args, "read": "2"})
                files.append((r1, r2))

    files = list(set(files))
    files = sum(map(list,files),[])
    return files


def get_samples():
    _, samples, _, _, _, _ = get_file_data()
    return list(set(samples))


def mode_auto():
    _, _, _, _, reads, _ = get_file_data()

    if set(reads) == set(["1","2"]):
        return "paired"
    elif set(reads) == set(["1"]):
        return "single"
    else:
        raise Exception("Wrong read id")


configfile: "/config.yaml"
samples = config['samples']
mode = config['kallisto']['mode']
pseudobam = bool(config['kallisto']['pseudobam'])
kallisto_threads = int(config['kallisto']['threads'])
readlength = int(config['kallisto']['readlength'])
readstd = int(config['kallisto']['readstd'])

if mode not in ["single","paired","auto"]:
    raise Exception("Wrong mode for kallisto, available modes are single, paired and auto")

if not samples:
    samples = get_samples()
else:
    samples = list(map(str,set(samples)))

if mode == "auto":
    mode = mode_auto()

print(samples)

rule all:
    input:
        "config.yaml",
        "multiqc/multiqc.html",
        "counts.csv",
        "genecounts.csv",
        "GeneCounts.pdf",
        expand("kallisto/{sample}/abundance.h5", sample=samples)

rule aggregate:
    input:
        abundance=expand("kallisto/{sample}/abundance.h5", sample=samples),
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
        expand("logs/kallisto/{sample}.log",sample=samples)
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
        reads=lambda wildcards: get_sample_files(wildcards.sample,mode=mode),
        index="/index/index.kidx",
        gtf="/index/annotations.gtf"
    output:
        "kallisto/{sample}/abundance.h5",
        "kallisto/{sample}/abundance.tsv",
        "kallisto/{sample}/run_info.json",
        "kallisto/{sample}/pseudoalignments.bam" if pseudobam else []
    threads:
        kallisto_threads
    log:
        "logs/kallisto/{sample}.log"
    run:
        cmd = f"""kallisto quant -o kallisto/{wildcards.sample} -i {input.index} -t {kallisto_threads}"""

        if pseudobam:
            cmd += f""" --pseudobam --genomebam --gtf {input.gtf}"""
        if mode=="single":
            cmd += f""" --single -l {readlength} -s{readstd}"""
        cmd += f""" {input.reads}"""
        cmd += f""" &> {log}"""

        shell(cmd)

rule copy_config:
    input:
        "/config.yaml"
    output:
        "config.yaml"
    shell:
        "cp {input} {output}"
