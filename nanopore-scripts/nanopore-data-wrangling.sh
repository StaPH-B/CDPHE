#!/bin/bash
# Curtis Kapsak
# started: 12/4/18
# Permission to copy and modify is granted without warranty of any kind.

# Purpose(s) - to combine the sequencing_summary.txt files produced by Albacore processes (will
#              eventually be replaced by Guppy and it's output.
#
#            - Run NanoPlot on raw, basecalled reads (Albacore summary files for raw, basecalled reads)
#            - Run NanoPlot on trimmed and filtered reads (see results of trimming/filtering)
#
#            - Porechop reads to remove adapter and barcode sequences
#
#            - Tiptoft on porechopped reads (all) to look for plasmid replicon sequences
#
#            - Filtlong script to generate histograms of read lengths, mean qualities, and window qualities
#            - Filtlong to obtain highest quality Nanopore reads, by using ILMN reads as reference
#
#            - Assemble genomes with Unicycler hybrid first, followed by LRO
#            - Run quast on assemblies
#            - generate summary file, similar to isolate_info_file in type_pipe script
#
#            - Annotate assemblies with Prokka
#
#            - Align ILMN reads to assemblies using bwa mem
#            - Align Nanopore reads to assemblies
#                - generate alignment stats and sorted bam file (for both alignments)


# REQUIREMENTS: - conda must be installed and the following environments created and available:
#                    - NanoPlot
#                    - Unicycler
#               - pigz (sudo apt-get install pigz)
#               - filtlong (installed from source, not in conda env)
#               - quast
#               - porechop  (installed from source, but installed via pip in "chop-filt-env")
#               - bwa
#               - minimap2
#               - prokka
#               - samtools
#               - tiptoft
#
#               - R1 and R2 ILMN reads as separate files for each isolate (cleaned ILMN reads)

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

# This function is necessary so that the bash script can activate/deactivate conda environments. "conda activate" doesn't work like normal
conda-activate () {
. /home/staphb/miniconda3/bin/activate $1
}
conda-deactivate () {
. /home/staphb/miniconda3/bin/deactivate $1
}

# Current directory structure (shortened to show mostly the output from one isolate - fast5/ has all DIRS present)
#top-level-dir
#├── bwamem-ilmn-alignments
#│   └── bc05-SRR5192920
#├── chopped-filtered-reads
#│   ├── bc01
#├── chopped-reads
#│   ├── BC01.fastq.gz
#│   ├── BC01-info-filtlong-script-output.txt
#│   ├── none.fastq.gz
#│   └── porechop-STDOUT.log
#├── clean-ilmn-reads
#│   ├── interleaved-cleaned-reads
#│   ├── SRR4342906.cleaned_R1.fastq.gz
#│   ├── SRR4342906.cleaned_R2.fastq.gz
#├── fast5
#│   ├── 0-200
#│   ├── 201-400
#│   ├── 401-600
#│   ├── 601-917
#│   ├── basecalled-reads-fastqs-0-200
#│   ├── basecalled-reads-fastqs-201-400
#│   ├── basecalled-reads-fastqs-401-600
#│   ├── basecalled-reads-fastqs-401-600_stopped99percent
#│   ├── basecalled-reads-fastqs-601-917
#│   ├── nanoplot-ouput-combined-seq-summary
#│   ├── nanoplot-ouput-combined-seq-summary-barcoded
#│   ├── nanoplot-ouput-combined-seq-summary-non-log
#│   └── sequencing_summary_combined.txt.gz
#├── minimap2-alignments
#│   └── bc05-SRR5192920
#├── tiptoft
#│   ├── bc04-SRR5057224
#└── unicycler-assemblies
#    ├── bc01-SRR4342906

THREADS=$(nproc --all)
export THREADS
echo "Number of threads set to: $THREADS"

remove_file tmp1
# find all files with _1.fastq in it and make a list of SRR identifiers in a file called "tmp1"
find chopped-debarcoded-reads/ -maxdepth 1 -name 'BC*.fastq.gz*' |cut -d '_' -f 1 |cut -d '/' -f 2 |cut -d '.' -f 1 >tmp1
declare -a tmp=()
tmp1='tmp1'
tmpfile=`cat $tmp1`
for line in $tmpfile; do
    tmp=("${tmp[@]}" "$line");
done
id=("${tmp[@]}" "${srr[@]}") #Combine the automatically generated list with the SRR list
id=($(printf "%s\n" "${id[@]}"|sort -u)) #Get all unique values and output them to an array
echo ${id[@]}

# commented out temporarily - CJK 2/27/19
## Nanoplot - first get summary of everything about raw basecalled reads, then for of each of the barcodes broken down
#if [[ -e ./fast5/nanoplot-ouput-combined-seq-summary/ ]]; then
#        echo "Skipping NanoPlotting of raw, basecalled reads, since sequencing_summary_combined.txt.gz exists."
#    else
#        # Nanoplot is currently installed in a conda environment, via pip, so this is required to turn on the environment
#        conda-activate nanoplot-env
#        # produce Nanoplot output on all reads, displaying read N50 line and log-transformed graphs
#        NanoPlot --summary fast5/sequencing_summary_combined.txt.gz -t ${THREADS} --loglength --N50 -o fast5/nanoplot-ouput-combined-seq-summary
#        # produce Nanoplot output per barcode
#        NanoPlot --summary fast5/sequencing_summary_combined.txt.gz -t ${THREADS} --N50 --loglength --barcoded -o fast5/per-barcode-nanoplot-ouput-combined-seq-summary
#        # deactivate conda env
#        conda-deactivate
#fi

# Porechop


# Filtlong


# Unicycler


# Prokka
make_directory prokka
# Make array called assemblylist
# find all assembly.fasta files in /unicycler-assemblies , put into an array 'assemblylist'
declare -a assemblylist=()
# for all unicycler produced assembliy.fasta files that exist, run prokka if it hasn't been run yet
# find all assembly.fasta files in /unicycler-assemblies , put into an array 'assemblylist'
# i variable is the full path to *.contigs.fasta file
for i in canu-assemblies/BC*/*.contigs.fasta; do
    echo "i is set to ${i} , adding to assemblylist array."
    assemblylist=("${assemblylist[@]}" "${i}")
    echo "assemblylist is set to:${assemblylist[@]}"
    # create a temp_var variable and shorten the name, so that it can be used as a prefix in Prokka
    # when creating the name for unicycler output DIR, make sure that you specify the nanopore and ILMN reads used and DO NOT use an underscore
    ##example: unicycler -o unicycler-assemblies/bc01-SRR11111111/fourth-try-bold-mode-on
    ##example: unicycler -o unicycler-assemblies/bc03-05-06-SRR5192920/sixth-try-normal-mode
    # temp_var is just the file name like Koxytoca.contigs.fasta
    temp_var=$(echo ${i} | cut -d '/' -f 3,4| sed -r 's/[/]+/_/g')
    echo "temp_var is set to:${temp_var}"
    # check to see if prokka DIR exists, if so skip, if not, run prokka
    if [ -e ./prokka/${temp_var} ]; then
        echo "Prokka has been run on ${temp_var} , Skipping."
    else
        make_directory prokka/${temp_var}
        echo "Prokka will now be run on :"${temp_var}
        export i temp_var
        docker run -e i -e temp_var -e THREADS --rm=True -u $(id -u):$(id -g) -v $PWD:/data staphb/prokka:1.13 /bin/bash -c \
        'prokka /data/${i} --outdir /data/prokka/${temp_var} --prefix ${temp_var} --cpus ${THREADS} --force'
    fi
done

## Abricate on all canu-assemblies
# set abricate_db_path in container. Must run as root to prevent permission errors
abricate_db_path=$(docker run --rm=True -v $PWD:/data staphb/abricate:0.8.7 /bin/bash -c 'find / -path "/abricate*/db"')
echo "abricate_db_path is set to:${abricate_db_path}"
export abricate_db_path
# set list of db's into a variable
databases=$(docker run -e abricate_db_path -e databases --rm=True -v $PWD:/data staphb/abricate:0.8.7 /bin/bash -c 'for i in $abricate_db_path/*; do b=`basename $i $abricate_db_path/`; databases+=("$b"); done; echo ${databases[@]}; export databases')
# convert the list of db's into an array
read -a db_array <<< ${databases}
echo "abricate db_array is set to:${db_array[@]}"

make_directory abricate
make_directory abricate/summary
for y in ${db_array[@]}; do
    if [[ -n "$(find -path ./abricate/summary/${y}_summary)" ]]; then
        echo "Abricate kadabricate! ${y} has been run"
        continue
    else
        for i in canu-assemblies/BC*/*.contigs.fasta; do
	    export i
            temp_var=$(echo ${i} | cut -d '/' -f 3,4| sed -r 's/[/]+/_/g')
            export temp_var
            echo "temp_var is set to:${temp_var}"
            docker run -e temp_var -e y -e i -e THREADS --rm=True -u $(id -u):$(id -g) -v $PWD:/data staphb/abricate:0.8.7 /bin/bash -c \
            'abricate --threads ${THREADS} -db ${y} /data/${i} > /data/abricate/${temp_var}_${y}.tab'
        done
    fi
    export y
    echo "variable y is set to:"${y}
    docker run -e y --rm=True -u $(id -u):$(id -g) -v $PWD:/data staphb/abricate:0.8.7 /bin/bash -c \
    'abricate --summary /data/abricate/*_${y}.tab > /data/abricate/summary/${y}_summary'
done
echo 'FINISHED RUNNING ABRICATE'


#echo ${assemblylist[@]}

# Prokka - untested - needs to be fixed
#for line in ${assemblylist}; do
#
#done
#    if [[ -n "$(find -path ./prokka/$i)" ]]; then
#        echo "Prokka has been run on isolate $i"
#    else
#        echo "Prokka will now be run on "$i
#        prokka unicycler-assemblies/$i/contigs.fasta --outdir prokka/$i --prefix $i
#    fi
#done

## remove lingering tmp1 file
#remove_file tmp1
