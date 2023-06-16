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
        debian-keyring


# Create a non-root user and switch to it
# RUN useradd -m builder && chown -R builder:builder /home/builder
# USER builder

# Add package builder cli to Container
WORKDIR /builder
COPY package_builder /builder
COPY requirements.txt /builder

ENV PATH=$PATH:/builder

ENV VIRTUAL_ENV=/builder/venv
RUN python3 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

RUN pip3 install --no-cache-dir -r requirements.txt

RUN mkdir /package
WORKDIR /package

# Run your cli.py script when the container launches
ENTRYPOINT ["package_builder.py"]
