#!/bin/bash
#Authors: Curtis Kapsak
#Usage: Script to download all staphb docker containers at once
#Permission to copy and modify is granted without warranty of any kind

docker pull staphb/abricate-v0.8.7:latest
docker pull staphb/mash:latest
docker pull staphb/quast-v5.0.0:latest
docker pull staphb/prokka-v1.13:latest
docker pull staphb/lyveset-v2.0:latest
docker pull staphb/spades-v3.12:latest
docker pull staphb/sratoolkit-v2.9.2:latest
docker pull staphb/serotypefinder-v1.1:latest
docker pull staphb/roary-v3.12.0:latest
docker pull staphb/kraken-v1.0:latest
docker pull staphb/sistr-v1.0.2:latest
docker pull staphb/seqsero-v1.0.1:latest
