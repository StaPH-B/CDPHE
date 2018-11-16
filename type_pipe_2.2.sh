#!/bin/bash
#Authors: Logan Fink, Curtis Kapsak
#Usage: script to type bacteria and characterize AMR
#Permission to copy and modify is granted without warranty of any kind
#Last revised 09/08/18 - LDF

#Set all the variables that need to be set
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
remove_file () {
    if [ -e $1 ];then
        rm -rf $1
    fi
}
#This function will check to make sure the directory doesn't already exist before trying to create it
make_directory () {
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

##### Move all fastq files from fastq_files directory up one directory, remove fastq_files folder #####
if [[ -n "$(find ./fastq_files)" ]]; then
    mv ./fastq_files/* .
    rm -rf ./fastq_files
fi

declare -a srr=() #PASTE IN ANY SRR NUMBERS INTO FILE named: SRR
while IFS= read -r line; do
    srr+=("$line")
done < ./SRR
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
for i in ${id[@]}; do
    if [[ $i =~ "SRR" ]]; then
        echo $i
        if [[ -n "$(find *$i* 2>/dev/null)" ]]; then
            echo "Files are here."
        else
            echo 'prefetching '$i'...'
            prefetch $i
            echo 'Creating read files for '$i'...'
            fastq-dump --gzip --skip-technical --dumpbase --split-files --clip $i
        fi
    fi
done

##### These are the QC trimming scripts as input to trimClean #####
make_directory clean
echo "cleaning cleaning cleaning cleaning cleaning cleaning cleaning cleaning cleaning cleaning cleaning cleaning cleaning cleaning cleaning cleaning cleaning cleaning cleaning cleaning cleaning cleaning cleaning"
for i in *R1_001.fastq.gz; do
    b=`basename ${i} _R1_001.fastq.gz`;
    if [[ -n "$(find -path ./clean/${b}.cleaned.fastq.gz)" ]]; then
        continue
    else
        run_assembly_shuffleReads.pl ${b}"_R1_001.fastq.gz" ${b}"_R2_001.fastq.gz" > clean/${b}.fastq;
        echo ${b};
        run_assembly_trimClean.pl -o clean/${b}.cleaned.fastq.gz -i clean/${b}.fastq --nosingletons;
        remove_file clean/${b}.fastq;
    fi
done
if [ -s "SRR" ]; then
    for j in *_1.fastq.gz; do
        c=`basename ${j} _1.fastq.gz`;
        if [[ -n "$(find -path ./clean/${c}.cleaned.fastq.gz)" ]]; then
            continue
        else
            echo "WHAT DO YOU EVEN THINK C IS? "${c}
            run_assembly_shuffleReads.pl ${c}"_1.fastq.gz" ${c}"_2.fastq.gz" > clean/${c}.fastq;
            echo ${c};
            run_assembly_trimClean.pl -i clean/${c}.fastq -o clean/${c}.cleaned.fastq.gz --nosingletons;
            remove_file clean/${c}.fastq;
        fi
    done
else
    echo "There are no SRR numbers in this run"
fi
remove_file ./clean/\**

##### Kraken is called here as a contamination check #####
#Mini kraken is used here, since it takes up less space.  If results are inconclusive, can run kraken with the larger database
#praise cthulhu.
make_directory kraken_output
echo 'SETTING KRAKEN DATABASE PATH'
KRAKEN_DB=$(find /home/$USER/ -mount -path "*/kraken/minikraken_CURRENT")
echo 'KRAKEN DATABASE PATH SET TO:' $KRAKEN_DB
echo $KRAKEN_DB
remove_file kraken_output/top_kraken_species_results
for i in ${id[@]}; do
    if [[ -n "$(find . -path ./kraken_output/${i}/kraken_species.results 2>/dev/null)" ]]; then
        echo "Isolate "${i}" has been krakked."
    else
        echo "RELEASE THE (mini)KRAKEN on isolate ${i}!!!"
        make_directory ./kraken_output/${i}/;
        kraken --preload --db $KRAKEN_DB --gzip-compressed --fastq-input ./clean/*${i}*.cleaned.fastq.gz > ./kraken_output/${i}/kraken.output;
        kraken-report --db $KRAKEN_DB --show-zeros ./kraken_output/${i}/kraken.output > ./kraken_output/${i}/kraken.results;
        awk '$4 == "S" {print $0}' ./kraken_output/${i}/kraken.results | sort -s -r -n -k 1,1 > ./kraken_output/${i}/kraken_species.results;
        echo ${i} >> ./kraken_output/top_kraken_species_results;
        head -10 ./kraken_output/$i/kraken_species.results >> ./kraken_output/top_kraken_species_results;
    fi
done

##### Run Quality and Coverage Metrics #####
## check to see if the run quality and coverage metrics have already been completed or not
for i in ${id[@]}; do
    if [[ -n "$(find -path ./clean/readMetrics.tsv 2>/dev/null)" ]]; then
		echo 'Run quality and coverage metrics have been generated'
	else
		echo 'Running run_assembly_readMetrics.pl and generating readMetrics.tsv'
		run_assembly_readMetrics.pl ./clean/*.fastq.gz --fast --numcpus 12 -e "$SEQUENCE_LEN"| sort -k3,3n > ./clean/readMetrics.tsv
	fi
done

##### Run SPAdes de novo genome assembler on all cleaned, trimmed, fastq files #####
make_directory ./spades_assembly_trim
for i in ${id[@]}; do
    if [[ -n "$(find -path ./spades_assembly_trim/$i/contigs.fasta 2>/dev/null)" ]]; then #This will print out the size of the spades assembly if it already exists
        size=$(du -hs ./spades_assembly_trim/$i/contigs.fasta | awk '{print $1}');
        echo 'File exists and is '$size' big.'
    else
        echo 'constructing assemblies for '$i', could take some time...'
         spades.py --pe1-12 ./clean/*${i}*.cleaned.fastq.gz -o spades_assembly_trim/${i}/ --careful
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

##### Run quast assembly statistics for verification that the assemblies worked #####
make_directory quast
for i in ${id[@]}; do
    quast.py spades_assembly_trim/$i/contigs.fasta -o quast/$i
done

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
        echo ${i}
        mash sketch ./clean/*${i}*.cleaned.fastq.gz
        mv ./clean/*${i}*.cleaned.fastq.gz.msh ./mash/
        mash dist /home/staphb/databases/mash/refseq_CURRENT/*.msh ./mash/*${i}*.fastq.gz.msh > mash/${i}_distance.tab
        sort -gk3 mash/${i}_distance.tab -o mash/${i}_distance.tab
        echo $i >> ./mash/top_mash_results;
        head -10 mash/${i}_distance.tab >> ./mash/top_mash_results;
    fi
done

##### Create list of samples and how they were identified by MASH (E. coli or Salmonella) #####  #PROBLEM: The classifications aren't always the species name, they are sometimes just identifiers...
#Thanks to Kevin Libuit of DGS Virginia for the frame work of the following code for MASH, serotypeFinder and SeqSero.
make_directory ./mash/sample_id
echo "sep=;"  > ./mash/sample_id/raw.csv && echo "Sample; MASH-ID; P-value" >> ./mash/sample_id/raw.csv
for i in ${id[@]}; do
     echo "${i}; $(head -1 ./mash/${i}_distance.tab | sed 's/.*-\.-//' | grep -o '^\S*' | sed -e 's/\(.fna\)*$//g'); $(head -1 ./mash/${i}_distance.tab | awk '{ print $3 }')"
     echo "${i}; $(head -1 ./mash/${i}_distance.tab | sed 's/.*-\.-//' | grep -o '^\S*' | sed -e 's/\(.fna\)*$//g'); $(head -1 ./mash/${i}_distance.tab | awk '{ print $3 }')" >> ./mash/sample_id/raw.csv
done

# database of H and O type genes
database="$(find /home/$USER/ -mount -path "*/serotypefinder/database")"
# serotypeFinder requires legacy blast
blast="/opt/blast-2.2.26/"

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
        # Run serotypeFinder for all Ecoli isolates and output to serotypeFinder_output/<sample_name>
        serotypefinder.pl -d $database -i ./spades_assembly_trim/${i}/contigs.fasta -b $blast  -o ./serotypeFinder_output/${i} -s ecoli -k 95.00 -l 0.60
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
for i in $sal_isolates; do
#for i in ${id[@]}; do #In case of emergency (classification acting up), uncomment this line to serotype every isolate using SeqSero, comment out line above
    # Check if SeqSero output exists for each Salmonenlla spp. isolate; skip if so
    if [[ -n "$(find -path ./SeqSero_output/${i}/Seqsero_result.txt 2>/dev/null)" ]]; then
        echo "Skipping ${i}. ${i} has already been serotyped with SeqSero."
    else
        # Run SeqSero for all Salmonella spp. isolates and output to SeqSero_output/<sample_name>"
        if (find ./*$i*_[1,2]*fastq.gz); then
            SeqSero.py -m2 -i ./*${i}*_[1,2]*fastq.gz
            make_directory ./SeqSero_output/$i
            mv ./SeqSero_result*/*.txt ./SeqSero_output/$i
            remove_file ./SeqSero_result*
        elif (find ./*$i*R[1,2]*fastq.gz); then
            SeqSero.py -m2 -i ./*${i}*R[1,2]*fastq.gz
            make_directory ./SeqSero_output/$i
            mv ./SeqSero_result*/*.txt ./SeqSero_output/$i
            remove_file ./SeqSero_result*
        fi
    fi
    echo ${i} >> ./SeqSero_output/all_serotype_results
    head -10 ./SeqSero_output/${i}/Seqsero_result.txt >> ./SeqSero_output/all_serotype_results
    echo >> ./SeqSero_output/all_serotype_results
    if [[ -n "$(find -path ./sister/${i}_sistr-results)" ]]; then
        continue
    else
        sistr -i ./spades_assembly_trim/$i/contigs.fasta ${i} -f tab -o sistr/${i}_sistr-results
    fi
done

#####This section provides data on the virulence and antibiotic resistance profiles for each isolates, from the databases that make up abricate
echo 'Setting abricate db PATH'
abricate_db_path=$(find /home/$USER/ -mount -path "*/abricate/db")
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
    for i in ${id[@]}; do
        abricate -db ${y} spades_assembly_trim/${i}/contigs.fasta > abricate/${i}_${y}.tab
    done
    abricate --summary ./abricate/*_${y}.tab > ./abricate/summary/${y}_summary
done
echo 'FINISHED RUNNING ABRICATE'

#####Create a file with all the relevant run info
remove_file isolate_info_file.tsv
qc_metric_head=$(head -1 ./clean/readMetrics.tsv)
echo -e "$qc_metric_head\tcontigs\tlargest_contig\ttotal_length\tN50\tL50" >> isolate_info_file.tsv
for i in ${id[@]}; do
    qc_metric=$(grep "${i}" ./clean/readMetrics.tsv)
    contigs=$(tail -9 ./quast/${i}/report.txt |grep "contigs" |tr -s ' '|cut -d' ' -f3)
    largest_contig=$(tail -9 ./quast/${i}/report.txt |grep "Largest contig" |tr -s ' '|cut -d' ' -f3)
    total_length=$(tail -9 ./quast/${i}/report.txt |grep "Total length" |tr -s ' '|cut -d' ' -f3)
    N50=$(tail -9 ./quast/${i}/report.txt |grep "N50" |tr -s ' '|cut -d' ' -f2)
    L50=$(tail -9 ./quast/${i}/report.txt |grep "L50" |tr -s ' '|cut -d' ' -f2)
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
echo "********************************"
echo "type_pipe pipeline has finished."
echo "********************************"
