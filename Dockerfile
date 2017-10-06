FROM ubuntu:16.04

RUN apt-get update

RUN apt-get install -y \
    git cmake zlib1g libhdf5-dev build-essential wget curl unzip jq bc && \
    rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/makaho/kallisto.git && \
    cd kallisto && mkdir build && cd build && cmake .. && make && make install && \
    cd /root && rm -rf kallisto

COPY scripts /scripts

ENTRYPOINT ["bash","/scripts/run-all.sh"]
