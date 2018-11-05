#!/bin/bash
#Authors: Curtis Kapsak
#Usage: Script to download all staphb docker images used in CO piplines
#Permission to copy and modify is granted without warranty of any kind

docker pull staphb/abricate:0.8.7
docker pull staphb/mash:2.1
docker pull staphb/quast:5.0.0
docker pull staphb/prokka:1.13.3
docker pull staphb/lyveset:2.0.1
docker pull staphb/spades:3.12.0
docker pull staphb/sratoolkit:2.9.2
docker pull staphb/serotypefinder:1.1
docker pull staphb/roary:3.12.0
docker pull staphb/kraken:1.0
docker pull staphb/sistr:1.0.2
docker pull staphb/seqsero:1.0.1
