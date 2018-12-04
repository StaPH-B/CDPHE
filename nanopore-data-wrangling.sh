#!/bin/bash
# Curtis Kapsak
# 11/28/18

# Purpose(s) - to combine the sequencing_summary.txt files produced by Albacore processes
#            - Run NanoPlot on


# REQUIREMENTS: - conda must be installed and the following environments created and available:
#                    - asdf
#               - pigz
#               - filtlong (installed from source, not in conda env)
#               - 
#               - 

# This function will check if the file exists before trying to remove it
remove_file () {
    if [ -e $1 ];then
        rm -rf $1
    fi
}
# This function will check to make sure the directory doesn't already exist before trying to create it
make_directory () {
    if [ -e $1 ]; then
        echo "Directory "$1" already exists"
    else
        mkdir $1
        echo "Directory "$1" has been created"
    fi
}


# Nanoplot - first get summary of everything about raw basecalled reads, then for of each of the barcodes broken down
conda activate nanoplot-env


NanoPlot --summary sequencing_summary_combined.txt.gz -t 24 --loglength --N50 -o nanoplot-ouput-combined-seq-summary
NanoPlot --summary sequencing_summary_combined.txt.gz -t 24 --N50 --loglength --barcoded -o 
nanoplot-ouput-combined-seq-summary-barcoded
