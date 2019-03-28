#!/bin/bash
#Authors: Logan Fink, Curtis Kapsak
#Usage: script to type bacteria and characterize AMR
#Permission to copy and modify is granted without warranty of any kind
#Last revised 09/08/18 - LDF

#Set all the variables that need to be set

version="2.3"
#Print out the line after the current line in the script, and print the evaluation
#of how it will be executed
print_next_command() {
    current_line=$(($1+1))
    range=$(($1+1))
    x=0
    while [ $x == 0 ]; do
        p=$(sed -n ${range}'p' /home/staphb/scripts/type_pipe_$version-dockerized.sh)
        if [[ $p == *\\ ]]; then
            range=$(($range+1))
        else
            x+=1
        fi
    done
    if [[ $range == $current_line ]]; then
        #echo $(sed -n ${current_line}'p' /home/staphb/scripts/type_pipe_$version-dockerized.sh)
        line_data=$(sed -n ${current_line}'p' /home/staphb/scripts/type_pipe_$version-dockerized.sh)
        line_data=$(echo $line_data | sed "s/'//g")
        #echo line_data
        output_prefix=''
        if [[ $line_data == *'>'* ]]; then
            end=${line_data##*>}
            output_prefix='Output file: '
            line_data=${line_data%%>*}
        fi
        eval echo $line_data
        eval echo $output_prefix$end
    else
        #echo $(sed -n ${current_line}','${range}'p' /home/staphb/scripts/type_pipe_$version-dockerized.sh)
        line_data=$(sed -n ${current_line}','${range}'p' /home/staphb/scripts/type_pipe_$version-dockerized.sh)
        line_data=$(echo $line_data | sed "s/'//g")
        #echo $line_data
        output_prefix=''
        if [[ $line_data == *'>'* ]]; then
            end=${line_data##*>}
            output_prefix='Output file: '
            line_data=${line_data%%>*}
        fi
        eval echo $line_data
        eval echo $output_prefix$end
    fi
}

#print_next_command() {
#    current_line=$(($1+1))
#    range=$(($1+1))
#    x=0
#    while [ $x == 0 ]; do
#        p=$(sed -n ${range}'p' /home/staphb/scripts/type_pipe_$version-dockerized.sh)
#        if [[ $p == *\\ ]]; then
#            range=$(($range+1))
#        else
#            x+=1
#        fi
#    done
#    if [[ $range == $current_line ]]; then
#        #echo $(sed -n ${current_line}'p' /home/staphb/scripts/type_pipe_$version-dockerized.sh)
#        eval echo $(sed -n ${current_line}'p' /home/staphb/scripts/type_pipe_$version-dockerized.sh)
#    else
#        #echo $(sed -n ${current_line}','${range}'p' /home/staphb/scripts/type_pipe_$version-dockerized.sh)
#        eval echo $(sed -n ${current_line}','${range}'p' /home/staphb/scripts/type_pipe_$version-dockerized.sh)
#    fi
#}

#Get the info from the sequencing length flag
while test $# -gt 0
do
    case $1 in
        -l)
            SEQUENCE_LEN=$2
            shift
            ;;
    esac
    shift
done

#This function will check if the file exists before trying to remove it
remove_file() {
    if [ -e $1 ];then
        echo "File $1 has been removed"
        rm -rf $1
    fi
}
#This function will check to make sure the directory doesn't already exist before trying to create it
make_directory() {
    if [ -e $1 ]; then
        echo "Directory "$1" already exists"
    else
        mkdir $1
        echo "Directory "$1" has been created"
    fi
}

if [ -z "$SEQUENCE_LEN" ]; then
    SEQUENCE_LEN=5000000
fi
echo "Sequence Length: $SEQUENCE_LEN"

#####Number of threads-specific to linux
#THREADS=$(nproc --all)
#####Number of threads-specific to Mac
#sysctl -n hw.ncpu
#####Number of threads-cross platform
THREADS=$(python -c 'import multiprocessing as mp; print(mp.cpu_count())')
echo "Number of threads set to: $THREADS"
export THREADS

##### Check to see if docker is installed #####
if [ -z $(which docker) ]; then
   echo "Docker is not installed, Please see https://github.com/StaPH-B/scripts/blob/master/image-information.md#docker-ce for instructions on how to install Docker. Now exiting."
   exit
else
    echo "$(docker --version) is installed."
fi

##### Function and check to see if Docker images are downloaded, if not, download them with docker pull #####
docker_image_check () {
if [ -z $(docker images -q $1) ]; then
    docker pull $1
else
    echo "Docker image $1 already exists locally."
fi
}
# gotta check em all! gotta check em all! Dock-er-mon!
echo "Now checking to see if all necessary docker images are downloaded..."
docker_image_check staphb/sratoolkit:2.9.2
docker_image_check staphb/lyveset:2.0.1
docker_image_check staphb/kraken:1.0
docker_image_check staphb/spades:3.12.0
docker_image_check staphb/mash:2.1
docker_image_check staphb/serotypefinder:1.1
docker_image_check staphb/seqsero:1.0.1
docker_image_check staphb/sistr:1.0.2
docker_image_check staphb/abricate:0.8.7
docker_image_check staphb/bwa:0.7.17
docker_image_check staphb/samtools:1.9

##### Move all fastq files from fastq_files directory up one directory, remove fastq_files folder #####
if [[ -e ./fastq_files ]]; then
    echo "Moving fastq files from ./fastq_files to ./ (top-level DIR)"
    mv ./fastq_files/* .
    rm -rf ./fastq_files
fi

declare -a srr=() #PASTE IN ANY SRR NUMBERS INTO FILE named: SRR
while IFS= read -r line; do
    srr+=("$line")
done < ./SRR 2>/dev/null
#find . -maxdepth 1 -name '*fastq*' |cut -d '-' -f 1|cut -d '_' -f 1 |cut -d '/' -f 2 >tmp1 #output all fastq file identifiers in cwd to file tmp1 (the delimiters here are '-' and '_')
find . -maxdepth 1 -name '*fastq*' |cut -d '_' -f 1 |cut -d '/' -f 2 >tmp1 #output all fastq file identifiers in cwd to file tmp1 (the delimiters here are '_')
declare -a tmp=()
tmp1='tmp1'
tmpfile=`cat $tmp1`
for line in $tmpfile; do
    tmp=("${tmp[@]}" "$line");
done
id=("${tmp[@]}" "${srr[@]}") #Combine the automatically generated list with the SRR list
id=($(printf "%s\n" "${id[@]}"|sort -u)) #Get all unique values and output them to an array
echo ${id[@]}
remove_file tmp

##### Fetch and fastq-dump all reads from NCBI identified by "SRR" #####
for i in ${srr[@]}; do
    echo $i
    if [[ -n "$(find *$i* 2>/dev/null)" ]]; then
        echo "Files are here."
    else
        export i
        echo 'prefetching '$i'...'
        print_next_command $LINENO ${i}
        docker run -e i --rm=True -u $(id -u):$(id -g) -v $PWD:/data staphb/sratoolkit:2.9.2 /bin/bash -c \
        'prefetch -O /data '${i}
        echo 'now running fasterq-dump in container'
        print_next_command $LINENO ${i}
        docker run -e THREADS -e i --rm=True -u $(id -u):$(id -g) -v $PWD:/data staphb/sratoolkit:2.9.2 /bin/bash -c \
        'fasterq-dump --skip-technical --split-files -t /data/tmp-dir -e ${THREADS} -p '${i}'.sra'
        mv ${i}.sra_1.fastq ${i}_1.fastq
        mv ${i}.sra_2.fastq ${i}_2.fastq
        pigz ${i}_1.fastq
        pigz ${i}_2.fastq
        rm ${i}.sra
    fi
done
remove_file tmp-dir

##### These are the QC trimming scripts as input to trimClean #####
make_directory clean
echo "cleaning cleaning cleaning cleaning cleaning cleaning cleaning cleaning cleaning cleaning cleaning cleaning cleaning cleaning cleaning cleaning cleaning cleaning cleaning cleaning cleaning cleaning cleaning"
for i in *R1_001.fastq.gz; do
    b=`basename ${i} _R1_001.fastq.gz`;
    if [[ -n "$(find -path ./clean/${b}.cleaned.fastq.gz)" ]]; then
        continue
    else
        echo "LYVESET CONTAINER RUNNING SHUFFLEREADS.PL"
        print_next_command $LINENO ${b}
        docker run --rm=True -v $PWD:/data -u $(id -u):$(id -g) staphb/lyveset:2.0.1 \
        run_assembly_shuffleReads.pl /data/${b}"_R1_001.fastq.gz" /data/${b}"_R2_001.fastq.gz" > clean/${b}.fastq;
        echo ${b};
        echo "LYVESET CONTAINER RUNNING TRIMCLEAN.PL"
        print_next_command $LINENO ${b}
        docker run --rm=True -v $PWD:/data -u $(id -u):$(id -g) staphb/lyveset:2.0.1 \
        run_assembly_trimClean.pl --numcpus ${THREADS} -o /data/clean/${b}.cleaned.fastq.gz -i /data/clean/${b}.fastq --nosingletons;
        remove_file clean/${b}.fastq;
    fi
done
if [ -s "SRR" ]; then
    for j in *_1.fastq.gz; do
        c=`basename ${j} _1.fastq.gz`;
        if [[ -n "$(find -path ./clean/${c}.cleaned.fastq.gz)" ]]; then
            continue
        else
            echo "(run_assembly_shuffleReads.pl)Interleaving reads for:"${c}" using lyveset docker container"
            print_next_command $LINENO ${c}
            docker run --rm=True -v $PWD:/data -u $(id -u):$(id -g) staphb/lyveset:2.0.1 \
            run_assembly_shuffleReads.pl /data/${c}"_1.fastq.gz" /data/${c}"_2.fastq.gz" > clean/${c}.fastq;
            echo "(run_assembly_trimClean.pl) Trimming/cleaning reads for:"${c}" using lyveset docker container";
            print_next_command $LINENO ${c}
            docker run --rm=True -v $PWD:/data -u $(id -u):$(id -g) staphb/lyveset:2.0.1 \
            run_assembly_trimClean.pl --numcpus ${THREADS} -i /data/clean/${c}.fastq -o /data/clean/${c}.cleaned.fastq.gz --nosingletons;
            remove_file clean/${c}.fastq;
        fi
    done
else
    echo "There are no SRR numbers in this run"
fi
rm ./clean/\** 2>/dev/null

##### Kraken is called here as a contamination check #####
#Mini kraken is used here, since it takes up less space.  If results are inconclusive, can run kraken with the larger database
#praise cthulhu.
make_directory kraken_output

# Commenting this section out because the path to the kraken DB in the container is static
#echo 'SETTING KRAKEN DATABASE PATH'
#KRAKEN_DB=$(find /home/$USER/ -mount -path "*/kraken/minikraken_CURRENT")
#echo 'KRAKEN DATABASE PATH SET TO:' $KRAKEN_DB
#echo $KRAKEN_DB
for i in ${id[@]}; do
    if [[ -n "$(find . -path ./kraken_output/${i}/kraken_species.results 2>/dev/null)" ]]; then
        echo "Isolate "${i}" has been krakked."
    else
        echo "RELEASE THE (mini)KRAKEN on isolate ${i}!!!"
        make_directory ./kraken_output/${i}/;
        # export variable i to make it available to container
        export i
        echo "variable i is set to:"${i}
        print_next_command $LINENO ${i}
        docker run -e i -e THREADS --rm=True -v $PWD:/data -u $(id -u):$(id -g) staphb/kraken:1.0 /bin/bash -c \
        'kraken --preload --threads ${THREADS} --db /kraken-database/minikraken_20171013_4GB --gzip-compressed --fastq-input /data/clean/*${i}*.cleaned.fastq.gz > /data/kraken_output/${i}/kraken.output';
        echo "Running second Kraken command: kraken-report"
        print_next_command $LINENO ${i}
        docker run -e i --rm=True -v $PWD:/data -u $(id -u):$(id -g) staphb/kraken:1.0 /bin/bash -c \
        'kraken-report --db /kraken-database/minikraken_20171013_4GB --show-zeros /data/kraken_output/${i}/kraken.output > /data/kraken_output/${i}/kraken.results';
    fi
done
# make the top_kraken_species_results file without having to re-run kraken itself
remove_file kraken_output/top_kraken_species_results
for i in ${id[@]}; do
    awk '$4 == "S" {print $0}' ./kraken_output/${i}/kraken.results | sort -s -r -n -k 1,1 > ./kraken_output/${i}/kraken_species.results;
    echo ${i} >> ./kraken_output/top_kraken_species_results;
    head -10 ./kraken_output/$i/kraken_species.results >> ./kraken_output/top_kraken_species_results;
done

##### Run SPAdes de novo genome assembler on all cleaned, trimmed, fastq files #####
make_directory ./spades_assembly_trim
for i in ${id[@]}; do
    if [[ -n "$(find -path ./spades_assembly_trim/$i/contigs.fasta 2>/dev/null)" ]]; then #This will print out the size of the spades assembly if it already exists
        size=$(du -hs ./spades_assembly_trim/$i/contigs.fasta | awk '{print $1}');
        echo 'File exists and is '$size' big.'
    else
        echo 'constructing assemblies for '$i', could take some time...'
        # exporting `i` variable to make it available to the docker container
        export i
        echo "i is set to:"$i
        print_next_command $LINENO
        docker run -e i -e THREADS --rm=True -v $PWD:/data -u $(id -u):$(id -g) staphb/spades:3.12.0 /bin/bash -c \
        'spades.py --pe1-12 /data/clean/*$i*.cleaned.fastq.gz -t ${THREADS} --careful -o /data/spades_assembly_trim/${i}/'
        rm -rf ./spades_assembly_trim/$i/corrected \
		./spades_assembly_trim/$i/K21 \
                ./spades_assembly_trim/$i/K33 \
                ./spades_assembly_trim/$i/K55 \
                ./spades_assembly_trim/$i/K77 \
                ./spades_assembly_trim/$i/K99 \
                ./spades_assembly_trim/$i/K127 \
                ./spades_assembly_trim/$i/misc \
                ./spades_assembly_trim/$i/mismatch_corrector \
                ./spades_assembly_trim/$i/split_input \
                ./spades_assembly_trim/$i/tmp
    fi
done



##### Split cleaned reads into separate R1 and R2 files #####
# Use split, cleaned reads as input for a few different things - bwa mem, shovill, others?
make_directory ./split-clean
for i in ${id[@]}; do
    if [[ -e ./split-clean/${i}.cleaned_R1.fastq.gz  ]]; then
        echo "Reads for ${i}. Have already been split into two R1/2 files. Skipping."
    else
        export i
        echo "SPLITTING CLEANED READS FOR ${i}"
        docker run --rm=True -e i -v $PWD:/data -u $(id -u):$(id -g) staphb/lyveset:2.0.1 /bin/bash -c \
        'run_assembly_shuffleReads.pl -d /data/clean/${i}*.cleaned.fastq.gz -gz 1> /data/split-clean/${i}.cleaned_R1.fastq.gz 2> /data/split-clean/${i}.cleaned_R2.fastq.gz'
    fi
done

##### Align split cleaned reads to their spades assemblies using bwa mem #####
make_directory ./bwa
for i in ${id[@]}; do
    if [[ -e ./bwa/${i}.alignment.sorted.bam ]]; then
        echo "Cleaned, split reads for ${i} have already been aligned to it's assembly. Skipping."
    else
        # index the assembly first
        docker run --rm=True -v $PWD:/data -u $(id -u):$(id -g) staphb/bwa:0.7.17 \
        bwa index /data/spades_assembly_trim/${i}/contigs.fasta
        echo "Aligning cleaned, split reads to the assembly for ${i} with bwa mem (in Docker container)."
        docker run --rm=True -v $PWD:/data -u $(id -u):$(id -g) staphb/bwa:0.7.17 \
        bwa mem -t ${THREADS} /data/spades_assembly_trim/${i}/contigs.fasta /data/split-clean/${i}.cleaned_R1.fastq.gz /data/split-clean/${i}.cleaned_R2.fastq.gz > bwa/${i}.alignment.sam
        # change SAM to BAM
        docker run --rm=True -v $PWD:/data -u $(id -u):$(id -g) staphb/samtools:1.9 \
        samtools view -buS --threads ${THREADS} /data/bwa/${i}.alignment.sam > bwa/${i}.alignment.bam
        # sort the BAM
        docker run --rm=True -v $PWD:/data -u $(id -u):$(id -g) staphb/samtools:1.9 \
        samtools sort --threads ${THREADS} /data/bwa/${i}.alignment.bam -o /data/bwa/${i}.alignment.sorted.bam
        # remove intermediate alignment files, leaving only sorted bam for each isolate
        remove_file bwa/${i}.alignment.sam
        remove_file bwa/${i}.alignment.bam
    fi
done

##### Run Quality and Coverage Metrics #####
## check to see if the run quality and coverage metrics have already been completed or not
if [[ -n "$(find -path ./clean/readMetrics.tsv 2>/dev/null)" ]]; then
    echo 'Run quality and coverage metrics have been generated'
else
    export SEQUENCE_LEN
    echo 'Running run_assembly_readMetrics.pl and generating readMetrics.tsv'
    docker run --rm=True -e SEQUENCE_LEN -e THREADS -v $PWD:/data -u $(id -u):$(id -g) staphb/lyveset:2.0.1 /bin/bash -c \
    'run_assembly_readMetrics.pl /data/clean/*.fastq.gz --fast --numcpus ${THREADS} -e "$SEQUENCE_LEN"'| sort -k3,3n > ./clean/readMetrics.tsv
fi

##### Run Quality and Coverage Metrics using BAMs #####
## check to see if the run quality and coverage metrics have already been completed or not
if [[ -n "$(find -path ./split-clean/readMetrics.tsv 2>/dev/null)" ]]; then
    echo "Run quality and coverage metrics from BAMs have been generated"
else
    export SEQUENCE_LEN
    echo "Running run_assembly_readMetrics.pl on BAMs and generating split-clean/readMetrics.tsv"
    docker run --rm=True -e SEQUENCE_LEN -e THREADS -v $PWD:/data -u $(id -u):$(id -g) staphb/lyveset:2.0.1 /bin/bash -c \
    'run_assembly_readMetrics.pl --fast --numcpus ${THREADS} -e "$SEQUENCE_LEN" /data/bwa/*.alignment.sorted.bam'| sort -k3,3n > ./split-clean/readMetrics.tsv
fi

##### Run Shovill to assemble (using SPAdes) #####
#
## NOTE: This is currently set up to accept SRA reads with this file name suffixs: _1.fastq.gz
#                                                                                  _2.fastq.gz
#
## NOTE: this is set up to use the raw R1/R2 illuina reads as input, not cleaned reads
## May need to alter CG-pipeline scripts to produce cleaned, trimmed reads
## as non-interleaved fastqs. May not be necessary since Shovil does have options
## for trimming adapters w/ trimmomatic and does it's own read correction using Lighter
#make_directory ./shovill
#for i in ${id[@]}; do
#    if [[ -n "$(find -path ./shovill/$i/contigs.fa 2>/dev/null)" ]]; then #This will print out the size of the spades $
#        size=$(du -hs ./shovill/$i/contigs.fa | awk '{print $1}');
#        echo 'File exists and is '$size' big.'
#    else
#        echo 'constructing assemblies for '$i', could take some time...'
#        # exporting `i` variable to make it available to the docker container
#        export i
#        echo "i is set to:"$i" , running shovill (spades) now...."
#        print_next_command $LINENO
#        docker run -e i --rm=True -v $PWD:/data -u $(id -u):$(id -g) staphb/shovill:1.0.4 /bin/bash -c \
#        'shovill --outdir /data/shovill/${i}/ --R1 /data/*${i}*_1.fastq.gz --R2 /data/*${i}*_2.fastq.gz --ram 29 --cpus 0'
#    fi
#done

##### Run quast assembly statistics for verification that the assemblies worked #####
make_directory quast
for i in ${id[@]}; do
     if [[ -n "$(find -path ./quast/${i}_output_file 2>/dev/null)" ]]; then
        echo "Skipping "$i". It's spades assembly has already been QUASTed."
    else
        print_next_command $LINENO
    	docker run --rm=True -v $PWD:/data -u $(id -u):$(id -g) staphb/quast:5.0.0 \
    	quast.py --fast -t ${THREADS} /data/spades_assembly_trim/$i/contigs.fasta -o /data/quast/$i
    fi
done

##### Run quast on shovill assemblies and generate summary output files #####
#make_directory quast-shovill
#for i in ${id[@]}; do
#    if [[ -n "$(find -path ./quast-shovill/${i}_output_file 2>/dev/null)" ]]; then
#        echo "Skipping "$i". It's shovill assembly has already been QUASTed."
#    else
#        print_next_command $LINENO
#    	 docker run -e THREADS --rm=True -v $PWD:/data -u $(id -u):$(id -g) staphb/quast:5.0.0 \
#    	 quast.py --fast -t ${THREADS} /data/shovill/$i/contigs.fa -o /data/quast-shovill/$i
#    fi
#done

##### QUAST output file generation for shovill assemblies #####
#for i in ${id[@]}; do
#    remove_file quast-shovill/${i}_output_file
#    tail -n +3 ./quast-shovill/$i/report.txt | grep "contigs (>= 0 bp)" >> quast-shovill/${i}_output_file
#    tail -n +3 ./quast-shovill/$i/report.txt | grep "Total length (>= 0 bp)" >> quast-shovill/${i}_output_file
#    tail -n +10 ./quast-shovill/$i/report.txt | grep "contigs" >> quast-shovill/${i}_output_file
#    tail -n +10 ./quast-shovill/$i/report.txt | grep "N50" >> quast-shovill/${i}_output_file
#    #May need to add in some files which explain the limits for different organisms, eg acceptable lengths of genome for e coli, accep$
#done

##### QUAST quality check ######
for i in ${id[@]}; do
    remove_file quast/${i}_output_file
    tail -n +3 ./quast/$i/report.txt | grep "contigs (>= 0 bp)" >> quast/${i}_output_file
    tail -n +3 ./quast/$i/report.txt | grep "Total length (>= 0 bp)" >> quast/${i}_output_file
    tail -n +10 ./quast/$i/report.txt | grep "contigs" >> quast/${i}_output_file
    tail -n +10 ./quast/$i/report.txt | grep "N50" >> quast/${i}_output_file
    #May need to add in some files which explain the limits for different organisms, eg acceptable lengths of genome for e coli, acceptable N50 values, etc.....
done

make_directory mash
echo "Mashing files now! MASH MASH MASH MASH MASH MASH MASH MASH MASH MASH MASH MASH MASH MASH MASH MASH MASH MASH MASH MASH MASH MASH MASH MASH MASH MASH MASH "
for i in ${id[@]}; do
    if [[ -n "$(find -path ./mash/${i}_distance.tab 2>/dev/null)" ]]; then
        echo "Skipping "$i". It has already been monster MASHed."
    else
        export i
        echo "variable i is set to:"${i}
        print_next_command $LINENO
        docker run -e i -e THREADS --rm=True -u $(id -u):$(id -g) -v $PWD:/data staphb/mash:2.1 /bin/bash -c \
        'mash sketch -p ${THREADS} /data/clean/*${i}*.cleaned.fastq.gz'
        mv ./clean/*${i}*.cleaned.fastq.gz.msh ./mash/
        echo "running mash dist in container, variable i set to:"${i}
        print_next_command $LINENO
        docker run -e i -e THREADS --rm=True -u $(id -u):$(id -g) -v $PWD:/data staphb/mash:2.1 /bin/bash -c \
        'mash dist -p ${THREADS} /db/RefSeqSketchesDefaults.msh /data/mash/*${i}*.fastq.gz.msh > /data/mash/${i}_distance.tab'
        sort -gk3 mash/${i}_distance.tab -o mash/${i}_distance.tab
        echo $i >> ./mash/top_mash_results;
        head -10 mash/${i}_distance.tab >> ./mash/top_mash_results;
    fi
done

##### Create list of samples and how they were identified by MASH (E. coli or Salmonella) #####  #PROBLEM: The classifications aren't always the species name, they are sometimes just identifiers...
#Thanks to Kevin Libuit of DCLS Virginia for the frame work of the following code for MASH, serotypeFinder and SeqSero.
make_directory ./mash/sample_id
echo "sep=;"  > ./mash/sample_id/raw.csv && echo "Sample; MASH-ID; P-value" >> ./mash/sample_id/raw.csv
for i in ${id[@]}; do
     echo "${i}; $(head -1 ./mash/${i}_distance.tab | sed 's/.*-\.-//' | grep -o '^\S*' | sed -e 's/\(.fna\)*$//g'); $(head -1 ./mash/${i}_distance.tab | awk '{ print $3 }')"
     echo "${i}; $(head -1 ./mash/${i}_distance.tab | sed 's/.*-\.-//' | grep -o '^\S*' | sed -e 's/\(.fna\)*$//g'); $(head -1 ./mash/${i}_distance.tab | awk '{ print $3 }')" >> ./mash/sample_id/raw.csv
done

#### Commented out because blast and the serotypefinder database are static in the container and paths are in the docker run command
## database of H and O type genes
#database="$(find /home/$USER/ -mount -path "*/serotypefinder/database")"
## serotypeFinder requires legacy blast
#blast="/opt/blast-2.2.26/"

##### SerotypeFinder, if mash pointed to E. coli, this will tell us the serotype details #####
ecoli_isolates="$(awk -F ';' '$2 ~ /Escherichia_coli/' ./mash/sample_id/raw.csv | awk -F ';' '{print$1}')"
make_directory serotypeFinder_output
echo "E. coli "$ecoli_isolates
remove_file ./serotypeFinder_output/serotype_results
for i in $ecoli_isolates; do
    # Check if serotypeFinder output exists for each E.coli isolate; skip if so
    if ls ./serotypeFinder_output/${i}/results_table.txt  1> /dev/null 2>&1; then
        echo "Skipping ${i}. ${i} has already been serotyped with serotypeFinder."
    else
        export i
        echo "variable i is set to:"${i}
        # Run serotypeFinder for all Ecoli isolates and output to serotypeFinder_output/<sample_name>
        print_next_command $LINENO
        docker run -e i --rm=True -u $(id -u):$(id -g) -v $PWD:/data staphb/serotypefinder:1.1 /bin/bash -c \
        'serotypefinder.pl -d /serotypefinder/database -i /data/spades_assembly_trim/${i}/contigs.fasta -b /blast-2.2.26  -o /data/serotypeFinder_output/${i} -s ecoli -k 95.00 -l 0.60'
    fi
    # Copy serotypeFinder's predicted serotype
    o_type="$(awk -F $'\t' 'FNR == 7 {print $6}' ./serotypeFinder_output/${i}/results_table.txt)"
    h_type="$(awk -F $'\t' 'FNR == 3 {print $6}' ./serotypeFinder_output/${i}/results_table.txt)"
    ecoli_serotype="${o_type}:${h_type}"
    # Edit ecoli.csv to include SeqSero results
    echo ${i}';' $ecoli_serotype >> ./serotypeFinder_output/serotype_results
done

##### SeqSero, and SISTR, if mash pointed to a salmonella species, this will tell us the serotype details #####
sal_isolates="$(awk -F ';' '$2 ~ /Salmonella/' ./mash/sample_id/raw.csv | awk -F ';' '{print$1}')"
make_directory SeqSero_output
make_directory sistr
echo "Salmonella "$sal_isolates
oddity="See comments below*"
remove_file ./SeqSero_output/all_serotype_results
sistr_header="header"
remove_file ./sistr/sistr_summary_temp
remove_file ./sistr/sistr_summary
for i in $sal_isolates; do
#for i in ${id[@]}; do #In case of emergency (classification acting up), uncomment this line to serotype every isolate using SeqSero, comment out line above
    # Check if SeqSero output exists for each Salmonenlla spp. isolate; skip if so
    if [[ -n "$(find -path ./SeqSero_output/${i}/Seqsero_result.txt 2>/dev/null)" ]]; then
        echo "Skipping ${i}. ${i} has already been serotyped with SeqSero."
    else
        # Run SeqSero for all Salmonella spp. isolates and output to SeqSero_output/<sample_name>"
        if (find ./*$i*_[1,2]*fastq.gz); then
            export i
            echo "variable i is set to:"${i}
            print_next_command $LINENO
            docker run -e i --rm=True -u $(id -u):$(id -g) -v $PWD:/data staphb/seqsero:1.0.1 /bin/bash -c \
            'SeqSero.py -m2 -i /data/*${i}*_[1,2]*fastq.gz'
            make_directory ./SeqSero_output/$i
            mv ./SeqSero_result*/*.txt ./SeqSero_output/$i
            remove_file ./SeqSero_result*
        elif (find ./*$i*R[1,2]*fastq.gz); then
            export i
            echo "variable i is set to:"${i}
            print_next_command $LINENO
            docker run -e i --rm=True -u $(id -u):$(id -g) -v $PWD:/data staphb/seqsero:1.0.1 /bin/bash -c \
            'SeqSero.py -m2 -i /data/*${i}*R[1,2]*fastq.gz'
            make_directory ./SeqSero_output/$i
            mv ./SeqSero_result*/*.txt ./SeqSero_output/$i
            remove_file ./SeqSero_result*
        fi
    fi
    echo ${i} >> ./SeqSero_output/all_serotype_results
    head -10 ./SeqSero_output/${i}/Seqsero_result.txt >> ./SeqSero_output/all_serotype_results
    echo >> ./SeqSero_output/all_serotype_results
    if [[ -n "$(find -path ./sistr/${i}_sistr-results.tab)" ]]; then
        echo "${i} has a SISTR (file)."
    else
        print_next_command $LINENO
        docker run --rm=True -u $(id -u):$(id -g) -v $PWD:/data staphb/sistr:1.0.2 \
        sistr -i /data/spades_assembly_trim/$i/contigs.fasta ${i} -t ${THREADS} -f tab -o /data/sistr/${i}_sistr-results
    fi
    sistr_header="$(head -1 ./sistr/${i}_sistr-results.tab)"
    tail -n +2 ./sistr/${i}_sistr-results.tab >> ./sistr/sistr_summary_temp
done
echo $sistr_header
echo $sistr_header >> ./sistr/sistr_summary
grep -v "fasta_filepath" ./sistr/sistr_summary_temp >> ./sistr/sistr_summary
rm ./sistr/sistr_summary_temp

#####This section provides data on the virulence and antibiotic resistance profiles for each isolates, from the databases that make up abricate
echo 'Setting abricate db PATH'
abricate_db_path=$(find /home/$USER/ -mount -path "*/abricate*/db")
echo 'ABRICATE DB PATH SET'
declare -a databases=()
for i in $abricate_db_path/*;
    do b=`basename $i $abricate_db_path/`;
    databases+=("$b");
done
echo ${databases[@]}
make_directory abricate
make_directory abricate/summary
for y in ${databases[@]}; do
    if [[ -n "$(find -path ./abricate/summary/${y}_summary)" ]]; then
        echo "Abricate kadabricate! ${y} has been run"
        continue
    else
        for i in ${id[@]}; do
	    export i
            print_next_command $LINENO
            docker run -e y -e i -e THREADS --rm=True -u $(id -u):$(id -g) -v $PWD:/data staphb/abricate:0.8.7 /bin/bash -c \
            'abricate --threads ${THREADS} -db ${y} /data/spades_assembly_trim/${i}/contigs.fasta > /data/abricate/${i}_${y}.tab'
        done
    fi
    export y
    echo "variable y is set to:"${y}
    print_next_command $LINENO
    docker run -e y --rm=True -u $(id -u):$(id -g) -v $PWD:/data staphb/abricate:0.8.7 /bin/bash -c \
    'abricate --summary /data/abricate/*_${y}.tab > /data/abricate/summary/${y}_summary'
done
echo 'FINISHED RUNNING ABRICATE'

#####Create a file with all the relevant run info
## Shovill quast metrics included, but currently commented out because shovill is turned off too.
remove_file isolate_info_file.tsv
qc_metric_head=$(head -1 ./clean/readMetrics.tsv)
# header line to use without shovill
echo -e "$qc_metric_head\tcontigs\tlargest_contig\ttotal_length\tN50\tL50" >> isolate_info_file.tsv
# header line to use with shovill
#echo -e "$qc_metric_head\tcontigs\tshovill_contigs\tlargest_contig\tshovill_largest_contig\ttotal_length\tshovill_total_length\tN50\tshovill_N50\tL50\tshovill_L50" >> isolate_info_file.tsv
for i in ${id[@]}; do
    qc_metric=$(grep "${i}" ./clean/readMetrics.tsv)
    contigs=$(tail -9 ./quast/${i}/report.txt |grep "contigs" |tr -s ' '|cut -d' ' -f3)
#    shovill_contigs=$(tail -9 ./quast-shovill/${i}/report.txt |grep "contigs" |tr -s ' '|cut -d' ' -f3)
    largest_contig=$(tail -9 ./quast/${i}/report.txt |grep "Largest contig" |tr -s ' '|cut -d' ' -f3)
#    shovill_largest_contig=$(tail -9 ./quast-shovill/${i}/report.txt |grep "Largest contig" |tr -s ' '|cut -d' ' -f3)
    total_length=$(tail -9 ./quast/${i}/report.txt |grep "Total length   " |tr -s ' '|cut -d' ' -f3)
#    shovill_total_length=$(tail -9 ./quast-shovill/${i}/report.txt |grep "Total length" |tr -s ' '|cut -d' ' -f3)
    N50=$(tail -9 ./quast/${i}/report.txt |grep "N50" |tr -s ' '|cut -d' ' -f2)
#    shovill_N50=$(tail -9 ./quast-shovill/${i}/report.txt |grep "N50" |tr -s ' '|cut -d' ' -f2)
    L50=$(tail -9 ./quast/${i}/report.txt |grep "L50" |tr -s ' '|cut -d' ' -f2)
#    shovill_L50=$(tail -9 ./quast-shovill/${i}/report.txt |grep "L50" |tr -s ' '|cut -d' ' -f2)
    if [ -z "$contigs" ]; then
         contigs="N/A"
    fi
    if [ -z "$largest_contig" ]; then
         largest_contig="N/A"
    fi
    if [ -z "$total_length" ]; then
         total_length="N/A"
    fi
    if [ -z "$N50" ]; then
         N50="N/A"
    fi
    if [ -z "$L50" ]; then
         L50="N/A"
    fi

    echo -e "$qc_metric\t$contigs\t$largest_contig\t$total_length\t$N50\t$L50" >> isolate_info_file.tsv
    echo -e "$qc_metric\t$contigs\t$largest_contig\t$total_length\t$N50\t$L50"

    # use these lines if shovill is turned on and you want to compare between SPAdes and shovill-spades outputs
    #echo -e "$qc_metric\t$contigs\t$shovill_contigs\t$largest_contig\t$shovill_largest_contig\t$total_length\t$shovill_total_length\t$N50\t$shovill_N50\t$L50\t$shovill_L50" >> isolate_info_file.tsv
    #echo -e "$qc_metric\t$contigs\t$shovill_contigs\t$largest_contig\t$shovill_largest_contig\t$total_length\t$shovill_total_length\t$N50\t$shovill_N50\t$L50\t$shovill_L50"
done


##### This section is for adding the assembly metrics to the readMetrics.tsv file generated on the split-clean
##### reads (needed to see the median fragment length AKA insert size) and generating isolate_info_file_split-clean.tsv
## NOTE: shovill lines commented out below have NOT been adjusted/tested. Just keeping lines in case we switch to Shovill full time.
remove_file isolate_info_file_split-clean.tsv
echo -e "$qc_metric_head\tcontigs\tlargest_contig\ttotal_length\tN50\tL50" >> isolate_info_file_split-clean.tsv
# header line to use with shovill
#echo -e "$qc_metric_head\tcontigs\tshovill_contigs\tlargest_contig\tshovill_largest_contig\ttotal_length\tshovill_total_length\tN50\tshovill_N50\tL50\tshovill_L50" >> isolate_info_file.tsv
for i in ${id[@]}; do
    qc_metric=$(grep "${i}" ./split-clean/readMetrics.tsv)
    contigs=$(tail -9 ./quast/${i}/report.txt |grep "contigs" |tr -s ' '|cut -d' ' -f3)
#    shovill_contigs=$(tail -9 ./quast-shovill/${i}/report.txt |grep "contigs" |tr -s ' '|cut -d' ' -f3)
    largest_contig=$(tail -9 ./quast/${i}/report.txt |grep "Largest contig" |tr -s ' '|cut -d' ' -f3)
#    shovill_largest_contig=$(tail -9 ./quast-shovill/${i}/report.txt |grep "Largest contig" |tr -s ' '|cut -d' ' -f3)
    total_length=$(tail -9 ./quast/${i}/report.txt |grep "Total length   " |tr -s ' '|cut -d' ' -f3)
#    shovill_total_length=$(tail -9 ./quast-shovill/${i}/report.txt |grep "Total length" |tr -s ' '|cut -d' ' -f3)
    N50=$(tail -9 ./quast/${i}/report.txt |grep "N50" |tr -s ' '|cut -d' ' -f2)
#    shovill_N50=$(tail -9 ./quast-shovill/${i}/report.txt |grep "N50" |tr -s ' '|cut -d' ' -f2)
    L50=$(tail -9 ./quast/${i}/report.txt |grep "L50" |tr -s ' '|cut -d' ' -f2)
#    shovill_L50=$(tail -9 ./quast-shovill/${i}/report.txt |grep "L50" |tr -s ' '|cut -d' ' -f2)
    if [ -z "$contigs" ]; then
         contigs="N/A"
    fi
    if [ -z "$largest_contig" ]; then
         largest_contig="N/A"
    fi
    if [ -z "$total_length" ]; then
         total_length="N/A"
    fi
    if [ -z "$N50" ]; then
         N50="N/A"
    fi
    if [ -z "$L50" ]; then
         L50="N/A"
    fi

    echo -e "$qc_metric\t$contigs\t$largest_contig\t$total_length\t$N50\t$L50" >> isolate_info_file_split-clean.tsv
    echo -e "$qc_metric\t$contigs\t$largest_contig\t$total_length\t$N50\t$L50"

    # use these lines if shovill is turned on and you want to compare between SPAdes and shovill-spades outputs
    #echo -e "$qc_metric\t$contigs\t$shovill_contigs\t$largest_contig\t$shovill_largest_contig\t$total_length\t$shovill_total_length\t$N50\t$shovill_N50\t$L50\t$shovill_L50" >> isolate_info_file.tsv
    #echo -e "$qc_metric\t$contigs\t$shovill_contigs\t$largest_contig\t$shovill_largest_contig\t$total_length\t$shovill_total_length\t$N50\t$shovill_N50\t$L50\t$shovill_L50"
done

#### Remove the tmp1 file that lingers #####
remove_file tmp1

##### Move all of the fastq.gz files into a folder #####
make_directory fastq_files
for i in ${id[@]}; do
    if [[ -n "$(find *$i*fastq.gz)" ]]; then
        mv *$i*fastq.gz fastq_files
    fi
done
todays_date=$(date)
echo "*******************************************************************"
echo "type_pipe pipeline has finished on "$todays_date"."
echo "*******************************************************************"
