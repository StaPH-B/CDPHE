#!/bin/bash
# Curtis Kapsak
# 11/28/18

# Purpose - to combine the sequencing_summary.txt files produced by Albacore processes

# REQUIREMENTS:
# - Must be run from one DIR level above DIRs containing Albacore output

# create header by pulling it from an existing sequencing summary file and putting into a new file called
# sequencing_summary_combined.txt
cat $(ls basecalled-reads-fastqs-0-200/sequencing_summary.txt | head -1) | head -1 > sequencing_summary_combined.txt

# for all files in DIRs starting with "basecalled-reads"
for file in basecalled-reads*/sequencing_summary.txt; do
    cat $file | tail -n +2;
done >> sequencing_summary_combined.txt

# compress to save space
pigz sequencing_summary_combined.txt
