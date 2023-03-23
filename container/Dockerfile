ARG BASE_IMAGE=debian:bookworm-slim
FROM $BASE_IMAGE

ARG SOURCES_LIST

RUN echo -n "$SOURCES_LIST" > /etc/apt/sources.list
RUN rm -f /etc/apt/sources.list.d/*
RUN apt-get update -qy
RUN apt-get install -qy --no-install-recommends devscripts pristine-lfs debhelper rsync sph
 
