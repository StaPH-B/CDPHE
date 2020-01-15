# CDPHE Pipelines
The pipelines included in this repository are meant to be used for identification, characterization, and quality assessment of bacterial paired-end short read sequencing.  The pipelines themselves have been designed to accomodate fastq files coming from Illumina instruments, as well as fastq files which can be downloaded from NCBI's SRA database.  Previous versions of the pipelines were designed for specific virtual machines designed on the Google cloud platform, but we are actively trying to adapt the current versions to be platform agnostic.  

## INSTALLATION
The repository can be cloned with the following command:
```
git clone https://github.com/StaPH-B/CDPHE.git
```
The path to the repository should then be added to the $PATH variable on your linux distribution.

## PREREQUISITES
The versions of the pipelines which will be supported going forward require one dependency, and that is Docker.  In order to download Docker, follow the instructions in the [Docker User Guide](https://staph-b.github.io/docker-builds/). Docker is a platform which enables the creation of a "container" which contains an environment that should run identically on any system or compute environment.

## USE AND SPECIFIC EXAMPLES
There are a few different pipelines that can be run in tandem or independently of one another.

##### type_pipe
This pipeline trims and cleans reads, assembles the reads into contigs, searches the reads against a database to look for contamination, does a quick comparison to RefSeq using mash to identify a probable species identification, then further serotypes *E. coli* and *Salmonella* spp. The pipeline also runs the program Abricate to identify possible antibiotic resistance and virulence markers.

The usage is as follows:
```
#Run the folowing command from the same directory where all forward and reverse fastq files are located, or where there is a 
#file named "SRR" containing the short read archive identifiers for each organism on separate lines

run_type_pipe_[version]-dockerized.sh
```
Tags available for this pipeline: -l [approximate_genome_length, default 5000000]

##### pipeline_non-ref_tree_build
This pipeline trims and cleans reads, assembles the reads into contigs, then performs an annotation with prokka, a core genome alignment with roary, and builds a phylogenetic tree with RAxML.  This approach is similar to the [URF pipeline](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC5572866/) developed in Utah.  

The usage is as follows:
```
#Run the folowing command from the same directory where all forward and reverse fastq files are located, or where there is a 
#file named "SRR" containing the short read archive identifiers for each organism on separate lines

run_pipeline_non-ref_tree_build_[version]-dockerized.sh
```
Tags available for this pipeline: -l [approximate_genome_length, default 5000000]
