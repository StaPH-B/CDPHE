#!/bin/bash
#Authors: Curtis Kapsak
#Usage: Script to download staphb docker images used in pipeline_non-ref script
#Permission to copy and modify is granted without warranty of any kind

# REQUIREMENTS: docker must be installed

docker pull staphb/sratoolkit:2.9.2
docker pull staphb/lyveset:2.0.1
docker pull staphb/quast:5.0.0
docker pull staphb/prokka:1.13.3
docker pull staphb/roary:3.12.0
