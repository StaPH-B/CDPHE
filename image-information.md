To do:
  * asdf


### Software/Tools used (in order they appear in type_pipe_X.X.sh)
| Software | Version | commands used (if not the name of the tool) | Link |
| -------- | ------- | ------------------------------------------- | -------- |
| SRA-toolkit | 2.9.2 | `fastq-dump` | https://github.com/ncbi/sra-tools |
| Lyve-SET (includes CG-Pipeline scripts and raxml) | 2.0.1 (lyve-SET) | `run_assembly_shuffleReads.pl`, `run_assembly_trimClean.pl`, `run_assembly_readMetrics.pl` | https://github.com/lskatz/lyve-SET https://github.com/lskatz/CG-Pipeline |
| Kraken | 1.0 | | https://github.com/DerrickWood/kraken |
| SPAdes | 3.12.0 | | http://cab.spbu.ru/software/spades/ |
| QUAST | 5.0.0 | | https://github.com/ablab/quast |
| Mash | 2.1 | | https://github.com/marbl/Mash |
| SerotypeFinder | unknown (not listed on their bitbucket) | | https://bitbucket.org/genomicepidemiology/serotypefinder/ |
| SeqSero | 1.0.1 | | https://github.com/denglab/SeqSero |
| SISTR | 1.0.2 | | https://github.com/peterk87/sistr_cmd |
| ABRicate | 0.8.7 | | https://github.com/tseemann/abricate |

### Software/Tools used (in order they appear in pipeline_non-ref_tree_build_X.X.sh)
| Software | Version | commands used (if not the name of the tool) | Link |
| -------- | ------- | ------------------------------------------- | ---- |
| Prokka | 1.13.3 | | https://github.com/tseemann/prokka |
| Roary | 3.12.0 | | https://github.com/sanger-pathogens/Roary https://metacpan.org/pod/roary |
| raxml | x.x.x | | We use the raxml that comes with Lyve-SET, but original repo is here: https://github.com/stamatak/standard-RAxML |

### Other Software/Tools needed (not part of either script listed above)
| Software | Version | commands used (if not the name of the tool) | Link |
| -------- | ------- | ------------------------------------------- | ---- |
| Docker CE | 18.06.1-ce | | https://docs.docker.com/install/linux/docker-ce/ubuntu/ |
| Blast+ (legacy version) | 2.2.26 | | No longer available through NCBI's FTP site, available here: https://github.com/StaPH-B/docker-auto-builds/tree/master/serotypefinder/blast-2.2.26 |
| Basemount | 0.14 | | https://help.basespace.illumina.com/articles/descriptive/introduction-to-basemount/ |

#### Notes:
  * All software will be stored into the `$HOME/downloads` directory
  * This guide assumes the user has root access, if necessary.
  * This guide was written and tested using a clean install of Ubuntu 16.04-LTS on a Google Cloud Platform Compute Instance Virtual Machine. 

### SRA-toolkit
Instructions were followed for Binary installation on Ubuntu: https://github.com/ncbi/sra-tools/wiki/HowTo:-Binary-Installation
```
wget http://ftp-trace.ncbi.nlm.nih.gov/sra/sdk/2.9.2/sratoolkit.2.9.2-ubuntu64.tar.gz
tar -xzf sratoolkit.2.9.2-ubuntu64.tar.gz
rm -rf sratoolkit.2.9.2-ubuntu64.tar.gz
mv sratoolkit.2.9.2-ubuntu64/ ~/downloads
nano ~/.bashrc
# add this line to the end of your ~/.bashrc
export PATH=$PATH:~/downloads/sratoolkit.2.9.2-ubuntu64/bin
# refresh your shell by either logging out and back in, or run:
source ~/.bashrc
# test the install with:
which fastq-dump
# This will output the full path to sratoolkit.2.9.2-ubuntu64/bin/fastq-dump
# if it returns nothing, the executable is not in your $PATH

# test that the install is functional with:
fastq-dump --stdout SRR390728 | head -n 8

# output should be exactly this:
@SRR390728.1 1 length=72
CATTCTTCACGTAGTTCTCGAGCCTTGGTTTTCAGCGATGGAGAATGACTTTGACAAGCTGAGAGAAGNTNC
+SRR390728.1 1 length=72
;;;;;;;;;;;;;;;;;;;;;;;;;;;9;;665142;;;;;;;;;;;;;;;;;;;;;;;;;;;;;96&&&&(
@SRR390728.2 2 length=72
AAGTAGGTCTCGTCTGTGTTTTCTACGAGCTTGTGTTCCAGCTGACCCACTCCCTGGGTGGGGGGACTGGGT
+SRR390728.2 2 length=72
;;;;;;;;;;;;;;;;;4;;;;3;393.1+4&&5&&;;;;;;;;;;;;;;;;;;;;;<9;<;;;;;464262
```
Install instructions tested? YES 

### Lyve-SET/CG-pipeline/raxml
Installing Lyve-SET will also install the scripts from CG-pipeline that we use for cleaning the reads, and will also install raxml. So here's how to install Lyve-SET:
#### Lyve-SET
```
sudo apt-get update
sudo apt-get install perl\
                     libfile-slurp-perl\
                     openjdk-9-jre\
                     bioperl\
                     wget\
                     libz-dev\
                     git\
                     libncurses5-dev\
                     libncursesw5-dev\
                     build-essential\
                     ncbi-blast+\
                     libsvn-perl\
                     subversion\
                     libsvn1\
                     automake1.11\
                     libpthread-stubs0-dev
cd ~/downloads
wget https://github.com/lskatz/lyve-SET/archive/v2.0.1.tar.gz
tar -zxf v2.0.1.tar.gz
rm -rf v2.0.1.tar.gz

# try installing perl modules without sudo first, then if it fails try with sudo
(sudo) cpanm URI::Escape \
           File::Slurp \
           String::Escape \
           Test::Most \
           Bio::FeatureIO
cd ~/downloads/lyve-SET-
make install
# If 'make install' fails, I find it best to delete the entire lyve-set directory, re-extract
# from the tarball and to re-run 'make install' from the lyve-set directory again. 'make install'
# does not like to be run more than once because it tries to create files that it already created
# and then fails because those files are there.
nano ~/.bashrc
# add both of the following lines to the bottom of ~/.bashrc
export PATH=$PATH:~/downloads/lyve-SET-2.0.1/scripts
export PATH=$PATH:~/downloads/lyve-SET-2.0.1/lib/edirect
# save and close file
# refresh .bashrc with:
source ~/.bashrc
```
Install instructions tested? YES

### Kraken
#### Jellyfish install
Jellyfish must be installed prior to installing Kraken.
```
cd ~/downloads
wget https://github.com/gmarcais/Jellyfish/releases/download/v1.1.12/jellyfish-1.1.12.tar.gz
tar -zxf jellyfish-1.1.12.tar.gz
rm -rf jellyfish-1.1.12.tar.gz
cd jellyfish-1.1.12
./configure --prefix=/opt/
make -j 4
sudo make install
```
#### Kraken install
```
sudo apt-get install zlib1g-dev
cd ~/downloads
wget https://github.com/DerrickWood/kraken/archive/v1.0.tar.gz
tar -xzf v1.0.tar.gz
cd kraken-1.0
sudo mkdir /opt/kraken
sudo ./install_kraken.sh /opt/kraken/

nano ~/.bashrc
# add the following lines to .bashrc, save, refresh shell by logging in/out
export PATH=$PATH:/opt/kraken
export PATH=$PATH:/opt/jellyfish/bin

# test with:
which kraken
# or:
kraken -h
```
#### DL'ing miniKraken database
```
mkdir ~/databases/kraken/minikraken_CURRENT
cd ~/databases/kraken/minikraken_CURRENT
wget https://ccb.jhu.edu/software/kraken/dl/minikraken_20171019_4GB.tgz
tar -xzf minikraken_20171019_4GB.tgz
# re-name directory to /minikraken_CURRENT so that the type_pipe script can locate the database
mv minikraken_20171013_4GB/ minikraken_CURRENT/
```
Install instructions tested? YES

### SPAdes
```
wget http://cab.spbu.ru/files/release3.12.0/SPAdes-3.12.0-Linux.tar.gz 
tar -xzf SPAdes-3.12.0-Linux.tar.gz
rm -rf SPAdes-3.12.0-Linux.tar.gz

nano ~/.bashrc
# add this line to the end of your ~/.bashrc
export PATH=$PATH:~/downloads/SPAdes-3.12.0-Linux/bin
# refresh your shell by either logging out and back in, or run:
source ~/.bashrc
# test the install with:
which spades.py
# This will output the full path to SPAdes-3.12.0-Linux/bin/spades.py
# if it returns nothing, the executable is not in your $PATH

# test that the install is functional with:
spades.py --test
# output should look like this:
===== Assembling finished. Used k-mer sizes: 21, 33, 55

 * Corrected reads are in spades_test/corrected/
 * Assembled contigs are in spades_test/contigs.fasta
 * Assembled scaffolds are in spades_test/scaffolds.fasta
 * Assembly graph is in spades_test/assembly_graph.fastg
 * Assembly graph in GFA format is in spades_test/assembly_graph.gfa
 * Paths in the assembly graph corresponding to the contigs are in spades_test/contigs.paths
 * Paths in the assembly graph corresponding to the scaffolds are in spades_test/scaffolds.paths

======= SPAdes pipeline finished.

========= TEST PASSED CORRECTLY.

SPAdes log can be found here: spades_test/spades.log

Thank you for using SPAdes!
```
Install instructions tested? YES

### QUAST
```
sudo apt-get install zlib1g-dev pkg-config libfreetype6-dev libpng-dev wget g++ make perl python python-setuptools python-matplotlib
cd ~/downloads
wget https://downloads.sourceforge.net/project/quast/quast-5.0.0.tar.gz
tar -xzf quast-5.0.0.tar.gz
rm -rf quast-5.0.0.tar.gz

cd /quast-5.0.0
sudo ./setup.py install
# test that install worked, and quast.py is in the $PATH with:
which quast.py
# This will output: /usr/local/bin/quast.py
# if it returns nothing, the executable is not in your $PATH due to setup.py script not running correctly

# test the install with
sudo ./setup.py test
```
Install instructions tested? YES

### Mash
```
# These directions are for installing the dependency-free binary version of Mash
cd ~/downloads
wget https://github.com/marbl/Mash/releases/download/v2.1/mash-Linux64-v2.1.tar
tar -xvf mash-Linux64-v2.1.tar
rm -rf mash-Linux64-v2.1
nano ~/.bashrc
# add the following line to your .bashrc
export PATH=$PATH:~/downloads/mash-Linux64-v2.1
# save and close, refresh your shell:
source ~/.bashrc
# test install with:
mash
```
#### DL'ing Mash database
```
mkdir ~/databases/mash
cd ~/databases/mash
wget https://gembox.cbcb.umd.edu/mash/RefSeqSketchesDefaults.msh.gz
gunzip RefSeqSketchesDefaults.msh.gz
mkdir refseq_CURRENT
mv RefSeqSketchesDefaults.msh.gz refseq_CURRENT/
```
Install instructions tested? YES

### SerotypeFinder
```
sudo apt-get update
sudo apt-get install expat apache2 make wget curl git python bzip2 gcc libextutils-pkgconfig-perl libgd-perl 

#UPDATE - perlbrew not needed for serotypefinder to work. Ubuntu system perl is v5.22.1 and that works great!
#DO NOT RUN LINES BELOW WITH 3 #'S
### install perlbrew
###curl -L http://install.perlbrew.pl | bash
###source ~/perl5/perlbrew/etc/bashrc
###perlbrew init

###nano ~/.bashrc
# add the following line to the end of your .bashrc
###source ~/perl5/perlbrew/etc/bashrc
# save, exit, refresh your shell by logging out and in or run:
###source ~/.bashrc

###perlbrew install perl-5.23.0
###perlbrew switch perl-5.23.0
###perlbrew install-cpanm

# download serotypefinder.pl from my github repo (CGE removed this older version of SerotypeFinder from their Bitbucket repo)
mkdir ~/downloads/serotypefinder
cd ~/downloads/serotypefinder
wget https://raw.githubusercontent.com/StaPH-B/docker-auto-builds/master/serotypefinder/serotypefinder/serotypefinder.pl
wget https://raw.githubusercontent.com/StaPH-B/docker-auto-builds/master/serotypefinder/serotypefinder/README.md
chmod +x serotypefinder.pl

# download legacy blast from my docker-auto-builds repo and move it to /opt
mkdir ~/github
cd ~/github
git clone https://github.com/StaPH-B/docker-auto-builds.git
cd docker-auto-builds/serotypefinder
sudo cp -r blast-2.2.26/ /opt/

# install perl modules (perl dependencies)
# Try installing without sudo first, then if it fails then try sudo.
(sudo) cpanm inc::latest Module::Build \
 Data::Dumper \
 Getopt::Long \
 Try::Tiny::Retry \
 File::Temp \
 Clone \
 Convert::Binary::C \
 HTML::Entities \
 Data::Stag \
 Test::Most \
 CJFIELDS/BioPerl-1.6.924.tar.gz --force
```
Install instructions tested? YES

### SeqSero
```
sudo apt-get install python-biopython
wget https://github.com/denglab/SeqSero/archive/v1.0.1.tar.gz
tar -xzf v1.0.1.tar.gz
rm -rf v1.0.1.tar.gz

nano ~/.bashrc
# add the following line to your .bashrc
export PATH=$PATH:~/downloads/SeqSero-1.0.1
# log out and back in, or refresh your .bashrc
source ~/.bashrc
# test that SeqSero.py is in your path with:
which SeqSero.py
# test help options with 
SeqSero.py --help
```
Install instructions tested? YES

### SISTR
I *think* these commands will work, but as I mentioned below, I need to test on a clean Ubuntu VM to make sure it works.
```
sudo apt-get install python-pip python-dev build-essential
python -m pip install --upgrade pip
python -m pip install wheel numpy pandas
python -m pip install sistr_cmd
# test install and get version with:
sistr -V
# get help options with:
sistr -h
```
Install instructions tested? YES

The commands for installing SISTR below did NOT work. I've read that using `sudo` with pip is a BAD idea, and the second line below also upgrades the system `pip` which causes all sorts of errors. Above are commands that I *think* will work, but I need another clean install of Ubuntu to test against.

General advice for solving pip issues and links to solutions: https://github.com/pypa/pip/issues/5599
  * do NOT use `sudo` when using pip
  * it is a good idea to follow `pip` commands with `--user`
  * avoid upgrading system `pip`, if so, use the system package manager to do so (i.e. `apt or apt-get`)
```
sudo apt-get install python-pip python-dev build-essential 
# The below line is a BAD way to upgrade system pip
sudo pip install --upgrade pip
pip install wheel
sudo pip install numpy pandas
pip install sistr_cmd
```
Install instructions tested? NO

### ABRicate
```
# install dependencies
sudo apt-get install emboss bioperl ncbi-blast+ gzip unzip \
  libjson-perl libtext-csv-perl libfile-slurp-perl liblwp-protocol-https-perl libwww-perl

cd ~/downloads
wget https://github.com/tseemann/abricate/archive/v0.8.7.tar.gz
tar -zxf v0.8.7.tar.gz
rm -rf v0.8.7.tar.gz

nano ~/.bashrc
# add this line to the end of your ~/.bashrc:
export PATH=$PATH:~/downloads/abricate-0.8.7/bin
# refresh your shell by either logging out and back in, or run:
source ~/.bashrc
# test the install with:
which abricate
# should output the full path to /abricate-0.8.7/bin
# check dependencies with:
abricate --check
# index the databases with:
abricate --setupdb
# list databases with:
abricate --list

# Test abricate works by running it on included test dataset: assembly.fa 
abricate ~/downloads/abricate-0.8.7/test/assembly.fa >abricate-test-output.tab
# View output file with:
more abricate-test-output.tab
```
Install instructions tested? YES


### prokka
```
sudo apt-get install libdatetime-perl libxml-simple-perl libdigest-md5-perl git default-jre bioperl

cd ~/downloads
wget https://github.com/tseemann/prokka/archive/v1.13.3.tar.gz
tar -xzf v1.13.3.tar.gz
rm -rf v1.13.3.tar.gz

nano ~/.bashrc
# add this line to the end of your ~/.bashrc:
export PATH=$PATH:~/downloads/prokka-1.13.3/bin
# refresh your shell by either logging out and back in, or run:
source ~/.bashrc
# test the install with:
which prokka
# should output the full path to /prokka-1.13.3/bin
# index the databases with:
prokka --setupdb
# list databases with:
prokka --listdb
```
Install instructions tested? YES

### Roary
```
sudo apt-get install bedtools \
                     cd-hit \
                     ncbi-blast+ \
                     mcl \
                     parallel \
                     prank \
                     mafft \
                     fasttree
# The following perl module dependencies might be required, so go ahead and install with:
cpanm LWP::Simple \
      Text::CSV \
      JSON \
      File::Slurp
      
# install Roary version 3.12.0 specifically
cpanm -f AJPAGE/Bio-Roary-3.12.0.tar.gz

# OR install latest Roary version available through CPAN using:
cpanm -f Bio::Roary
```
You can ignore the warning that says something like: `Use of uninitialized value in require at /usr/local/lib/x86_64-linux-gnu/perl/5.22.1/Encode.pm line 69.`
It is a benign warning according to the developer of Roary: https://github.com/sanger-pathogens/Roary/issues/323#issuecomment-294887715

Install instructions tested? YES

### Docker CE
```
sudo apt-get update
sudo apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
(#Verify key: 
sudo apt-key fingerprint 0EBFCD88 
#should return: 
pub   4096R/0EBFCD88 2017-02-22
      Key fingerprint = 9DC8 5822 9FC7 DD38 854A  E2D8 8D81 803C 0EBF CD88
uid                  Docker Release (CE deb) <docker@docker.com>
sub   4096R/F273FCD8 2017-02-22)

sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
sudo apt-get update
sudo apt-get install docker-ce
# Test install with:
sudo docker run hello-world
```

##### Post-Docker-install steps to not have to use ‘sudo’ before every docker command
Pulled from here: https://docs.docker.com/install/linux/linux-postinstall/
```
sudo groupadd docker
sudo usermod -aG docker $USER
```
Log out and log back in (close & re-open terminal), so that your group membership is re-evaluated.

Verify that you can run docker images without sudo with:
`docker images`

If you initially ran Docker CLI commands using sudo before adding your user to the docker group, you may see the following error, which indicates that your ~/.docker/ directory was created with incorrect permissions due to the sudo commands.
```
WARNING: Error loading config file: /home/user/.docker/config.json -
stat /home/user/.docker/config.json: permission denied
```
To fix this problem, either remove the `~/.docker/` directory (it is recreated automatically, but any custom settings are lost), or change its ownership and permissions using the following commands:
```
sudo chown "$USER":"$USER" /home/"$USER"/.docker -R
sudo chmod g+rwx "/home/$USER/.docker" -R
```
Install instructions tested? YES

### Basemount
```
# ensure fusermount is available with:
fusermount --version
# if so then:
sudo bash -c "$(curl -L https://basemount.basespace.illumina.com/install)"
mkdir ~/Basespace
basemount Basespace/
# copy the given link into browser, log in to Basespace with credentials for basespace account
# now have access to basespace files, reads, etc.
```
