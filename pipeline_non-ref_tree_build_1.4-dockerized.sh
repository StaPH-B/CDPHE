#!/bin/bash
#Authors: Logan Fink, Curtis Kapsak
#Usage: script to create a reference free phylogenetic tree from a set of fastq files
#Permission to copy and modify is granted without warranty of any kind

version="2.4"
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

#Set number of threads, make variable global and accessible to docker containers
THREADS=$(nproc --all)
echo "Number of threads set to: $THREADS"
export THREADS

##### Check to see if docker is installed #####
if [ -z $(which docker) ]; then
   echo 'Docker is not installed, Please see https://github.com/StaPH-B/scripts/blob/master/image-information.md#docker-ce for instructions on how to install Docker. Now exiting.'
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
echo 'Now checking to see if all necessary docker images are downloaded...'
docker_image_check staphb/sratoolkit:2.9.2
docker_image_check staphb/lyveset:2.0.1
docker_image_check staphb/spades:3.12.0
docker_image_check staphb/quast:5.0.0
docker_image_check staphb/prokka:1.13
docker_image_check staphb/roary:3.12.0

##### Move all fastq files from fastq_files directory up one directory, remove fastq_files folder #####
if [[ -e ./fastq_files ]]; then
    echo 'Moving fastq files from ./fastq_files to ./ (top-level DIR)'
    mv ./fastq_files/* .
    rm -rf ./fastq_files
fi

declare -a srr=() #PASTE IN ANY SRR NUMBERS INTO FILE named: SRR
while IFS= read -r line; do
    srr+=("$line")
done < ./SRR
#find . -maxdepth 1 -name "*fastq*" |cut -d '-' -f 1|cut -d '_' -f 1 |cut -d '/' -f 2 >tmp1 #output all fastq file identifiers in cwd to file tmp1 (the delimiters here are '-' and '_')
find . -maxdepth 1 -name "*fastq*" |cut -d '_' -f 1 |cut -d '/' -f 2 >tmp1 #output all fastq file identifiers in cwd to file tmp1 (the delimiters here are '_')
declare -a tmp=()
tmp1='tmp1'
tmpfile=`cat $tmp1`
for line in $tmpfile; do
    tmp=("${tmp[@]}" "$line");
done
id=($(printf "%s\n" "${tmp[@]}"|sort -u)) #Get all unique values and output them to array
id=("${id[@]}" "${srr[@]}") #Combine the automatically generated list with the SRR list
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
    if [[ -n "$(find . -maxdepth 2 -name ${b}.cleaned.fastq.gz)" ]]; then
        continue
    else
        echo "LYVESET CONTAINER RUNNING SHUFFLEREADS.PL"
        print_next_command $LINENO ${i}
        docker run --rm=True -v $PWD:/data -u $(id -u):$(id -g) staphb/lyveset:2.0.1 \
        run_assembly_shuffleReads.pl /data/${b}"_R1_001.fastq.gz" /data/${b}"_R2_001.fastq.gz" > clean/${b}.fastq;
        echo ${b};
        echo "LYVESET CONTAINER RUNNING TRIMCLEAN.PL"
        print_next_command $LINENO ${i}
        docker run --rm=True -v $PWD:/data -u $(id -u):$(id -g) staphb/lyveset:2.0.1 \
        run_assembly_trimClean.pl -i /data/clean/${b}.fastq -o /data/clean/${b}.cleaned.fastq.gz --nosingletons --numcpus ${THREADS};
        remove_file clean/${b}.fastq;
    fi
done
for i in *_1.fastq.gz; do
    b=`basename ${i} _1.fastq.gz`;
    if find ./clean/${b}.cleaned.fastq.gz; then
        continue
    else
        echo '(run_assembly_shuffleReads.pl)Interleaving reads for:'${c}' using lyveset docker container'
        print_next_command $LINENO ${i}
        docker run --rm=True -v $PWD:/data -u $(id -u):$(id -g) staphb/lyveset:2.0.1 \
        run_assembly_shuffleReads.pl /data/${b}"_1.fastq.gz" /data/${b}"_2.fastq.gz" > clean/${b}.fastq;
        echo '(run_assembly_trimClean.pl) Trimming/cleaning reads for:'${c}' using lyveset docker container'
        print_next_command $LINENO ${i}
        docker run --rm=True -v $PWD:/data -u $(id -u):$(id -g) staphb/lyveset:2.0.1 \
        run_assembly_trimClean.pl -i /data/clean/${b}.fastq -o /data/clean/${b}.cleaned.fastq.gz --nosingletons --numcpus ${THREADS};
        remove_file clean/${b}.fastq;
    fi
done
remove_file ./clean/\**

##### Run SPAdes de novo genome assembler on all cleaned, trimmed, fastq files #####
make_directory ./spades_assembly_trim
for i in ${id[@]}; do
    if [[ -n "$(find -path ./spades_assembly_trim/$i/contigs.fasta 2>/dev/null)" ]]; then #This will print out the size of the spades assembly if it already exists
        size=$(du -hs ./spades_assembly_trim/$i/contigs.fasta | awk '{print $1}');
        echo 'File exists and is '$size' big.'
    else
        # make sure variable i is available to global env, to pass into container
        export i
        echo 'constructing assemblies for '$i', could take some time...'
        print_next_command $LINENO ${i}
        docker run -e i -e THREADS --rm=True -v $PWD:/data -u $(id -u):$(id -g) staphb/spades:3.12.0 /bin/bash -c \
        'spades.py --pe1-12 /data/clean/${i}*.cleaned.fastq.gz --careful -t ${THREADS} -o /data/spades_assembly_trim/${i}/'
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

make_directory new_temp
make_directory new_temp/spades_assemblies
for i in ${id[@]}; do
    if [[ -n "$(find -path ./spades_assembly_trim/$i/contigs.fasta 2>/dev/null)" ]]; then
        continue
    else
        cp ./clean/${i}*.cleaned.fastq.gz new_temp/
        spades_file=./clean/${i}*.cleaned.fastq.gz
        echo $spades_file
        export i
        echo 'constructing assemblies for '$i', second try...'
        print_next_command $LINENO ${i}
        docker run -e i -e THREADS --rm=True -v $PWD:/data -u $(id -u):$(id -g) staphb/spades:3.12.0 /bin/bash -c \
        'spades.py -o /data/new_temp/spades_assemblies/${i}/ -t ${THREADS} --pe1-12 /data/new_temp/${i}_*.cleaned.fastq.gz --careful'
        rm -rf ./new_tmp/spades_assemblies/$i/corrected \
		./new_tmp/spades_assemblies/$i/K21 \
                ./new_tmp/spades_assemblies/$i/K33 \
                ./new_tmp/spades_assemblies/$i/K55 \
                ./new_tmp/spades_assemblies/$i/K77 \
                ./new_tmp/spades_assemblies/$i/K99 \
                ./new_tmp/spades_assemblies/$i/K127 \
                ./new_tmp/spades_assemblies/$i/misc \
                ./new_tmp/spades_assemblies/$i/mismatch_corrector \
                ./new_tmp/spades_assemblies/$i/split_input \
                ./new_tmp/spades_assemblies/$i/tmp
    fi
done
mv new_temp/spades_assemblies/* spades_assembly_trim/
remove_file new_temp

##### Run quast assembly statistics for verification that the assemblies worked #####
make_directory quast
for i in ${id[@]}; do
    if [[ -e quast/${i}_output_file ]]; then
        echo "Skipping ${i}. It's SPAdes assembly has already been QUASTed."
    else
        print_next_command $LINENO ${i}
        docker run --rm=True -v $PWD:/data -u $(id -u):$(id -g) staphb/quast:5.0.0 \
        quast.py /data/spades_assembly_trim/$i/contigs.fasta -t ${THREADS} -o /data/quast/$i
    fi
done

##### Run prokka on all the isolates to get the core genomes and generate .gff files #####
make_directory ./prokka
for i in ${id[@]}; do
    if [[ -n "$(find -path ./prokka/$i)" ]]; then
        echo "Prokka has been run on this isolate."
    else
        export i
        echo "Prokka will now be run on "$i
        print_next_command $LINENO ${i}
        docker run -e i -e THREADS --rm=True -u $(id -u):$(id -g) -v $PWD:/data staphb/prokka:1.13 /bin/bash -c \
        'prokka /data/spades_assembly_trim/$i/contigs.fasta --outdir /data/prokka/$i --prefix $i --cpus ${THREADS}'
    fi
done

remove_file -r ./gff_files
make_directory ./gff_files #make directory to hold the .gff files output by prokka
cp prokka/*/*.gff gff_files/ #copy over the .gff files from prokka

##### Run roary using the .gff file folder #####
rm -rf roary
print_next_command $LINENO ${i}
docker run -e i -e THREADS --rm=True -u $(id -u):$(id -g) -v $PWD:/data staphb/roary:3.12.0 /bin/bash -c \
'roary -p ${THREADS} -e -n -v -f /data/roary /data/gff_files/*.gff'

##### Run raxml on the roary alignment to generate a tree #####
print_next_command $LINENO ${i}
docker run -e i --rm=True -u $(id -u):$(id -g) -v $PWD:/data staphb/lyveset:2.0.1 /bin/bash -c \
'raxmlHPC -m GTRGAMMA -p 12345 -x 12345 -s /data/roary/core_gene_alignment.aln -# 100 -n phylo_output -f a'
rm -rf raxml/
make_directory raxml
mv RAxML* raxml/

##### Move all of the fastq.gz files into a folder #####
make_directory fastq_files
for i in ${id[@]}; do
    if [[ -n "$(find *$i*fastq.gz)" ]]; then
        mv *$i*fastq.gz fastq_files
    fi
done
