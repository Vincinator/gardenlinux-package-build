FROM debian:testing-slim

RUN echo "deb-src http://deb.debian.org/debian bullseye main" >> /etc/apt/sources.list && \
    echo "deb-src http://deb.debian.org/debian-security bullseye-security main" >> /etc/apt/sources.list && \
    echo "deb-src http://deb.debian.org/debian trixie main" >> /etc/apt/sources.list && \
    echo "deb-src http://deb.debian.org/debian-security trixie-security main" >> /etc/apt/sources.list && \
    echo "deb-src http://deb.debian.org/debian sid main" >> /etc/apt/sources.list && \
    echo "deb-src http://deb.debian.org/debian experimental main" >> /etc/apt/sources.list

# Package Build CLI Dependencies
RUN apt-get update && \
    apt-get install -y python3 python3-venv python3-pip

# Debian Build dependencies
RUN apt-get install -qy --no-install-recommends \
        devscripts \
        pristine-lfs \
        rsync \
        git \
        ca-certificates \
        sudo \
        debian-keyring


RUN mkdir /output

RUN useradd -m builder && chown -R builder:builder /home/builder
RUN echo 'builder ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
USER builder

# Add package builder cli to Container
COPY --chown=builder:builder package_builder /builder
COPY --chown=builder:builder requirements.txt /builder
ENV PATH=$PATH:/builder

WORKDIR /builder

ENV VIRTUAL_ENV=/builder/venv
RUN python3 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

RUN pip3 install --no-cache-dir -r requirements.txt

ENTRYPOINT ["package_builder.py"]
