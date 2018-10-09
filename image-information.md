To do:
  * change serotypefinder install instructions to the ones I used for installing it into Docker
  * delete redundant sections
  * change order to reflect that of the type_pipe script
  * show location of various databases (Kraken, Mash, serotypefinder, etc.)
  * add install instructions for Basemount

### Software/Tools used (in order they appear in type_pipe_X.X.sh)
| Software | Version | commands used (if not the name of the tool) | Link |
| -------- | ------- | ------------------------------------------- | -------- |
| SRA-toolkit | 2.9.2 | `fastq-dump` | https://github.com/ncbi/sra-tools |
| CG-pipeline/Lyve-SET | x.x.x | `run_assembly_shuffleReads.pl`, `run_assembly_trimClean.pl`, `run_assembly_readMetrics.pl` | |
| Kraken | x.x.x | | |
| SPAdes | x.x.x. | | |
| QUAST | x.x.x | | |
| Mash | x.x.x | | |
| SerotypeFinder | x.x.x | | |
| SeqSero | x.x.x | | |
| SISTR | x.x.x | | |
| ABRicate | x.x.x | | |

### Software/Tools used (in order they appear in pipeline_non-ref_tree_build_X.X.sh)
| Software | Version | commands used (if not the name of the tool) | Link |
| -------- | ------- | ------------------------------------------- | ---- |
| Prokka | 1.13.3 | | https://github.com/tseemann/prokka |
| Roary | x.x.x | | |
| raxml | x.x.x | | |

### Other Software/Tools needed (not part of either script listed above)
| Software | Version | commands used (if not the name of the tool) | Link |
| -------- | ------- | ------------------------------------------- | ---- |
| Docker CE | x.x.x | | |
| Perlbrew | x.x.x | | |
| Blast+ (legacy version) | 2.2.26 | | No longer available through NCBI's FTP site, available here: INSERT LINK HERE |

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


### CG-pipeline/Lyve-SET

Install instructions tested?

### Kraken
jellyfish

download 1.1.11 into downloads folder

installed into `/opt/jellyfish`

kraken

cloned github into downloads

installed into `/opt/kraken`
```
sudo apt-get install zlib1g-dev
./configure --prefix=/opt/mash

git clone https://github.com/DerrickWood/kraken.git
sudo ./install_kraken.sh /opt/kraken/
```
OR
```
cd downloads
sudo git clone https://github.com/DerrickWood/kraken.git
cd kraken
sudo mkdir /opt/kraken
sudo ./install_kraken.sh /opt/kraken/
nano $HOME/.bash_vars
# add the following: export PATH=$PATH:/opt/jellyfish/bin
export PATH=$PATH:/opt/kraken
```
Install instructions tested?

### SPAdes

Install instructions tested?

### QUAST

Install instructions tested?

### Mash
```
git clone https://github.com/marbl/Mash.git
```
You may download and install the release version of Cap’n Proto like so:
```
curl -O https://capnproto.org/capnproto-c++-0.6.1.tar.gz
tar zxf capnproto-c++-0.6.1.tar.gz
cd capnproto-c++-0.6.1
./configure
make -j6 check
sudo make install
```
This will install `capnp`, the Cap’n Proto command-line tool. It will also install `libcapnp`,`libcapnpc`, and `libkj` in `/usr/local/lib` and headers in `/usr/local/include/capnp` and `/usr/local/include/kj`
```
sudo apt-get install libgsl-dev
sudo apt-get install libgsl2
sudo apt-get install autoconf
Sudo ./configure --prefix=/opt/mash
```
Install instructions tested?

### SerotypeFinder
TO-DO: ADD INSTRUCTIONS FOR GETTING SEROTYPEFINDER DATABASE FROM MY DOCKER REPO
```
ssh-keygen
save key in default location
don't give password
copy /home/staphb/.ssh/id_rsa.pub into bitbucket account @ https://bitbucket.org/account/user/your-username-here/ssh-keys/
git clone https://bitbucket.org/genomicepidemiology/serotypefinder.git
cd serotypefinder
./INSTALL_DB database
nano $HOME/.bash_vars
add the following: export PATH=$PATH:/home/staphb/downloads/serotypefinder
cd 
. .bash_vars
```
Install instructions tested?

### SeqSero
```
git clone https://github.com/denglab/SeqSero.git
sudo apt-get install python-biopython
```
python already at 2.7

bwa already installed

samtools already installed

did not install isPcr

OR

```
cd downloads
git clone https://github.com/denglab/SeqSero.git
sudo apt-get install python-biopython
nano $HOME/.bash_vars
add the following: export PATH=$PATH:/home/staphb/downloads/SeqSero
cd 
. .bash_vars
```
Install instructions tested?

### SISTR
```
sudo apt-get install python-pip python-dev build-essential 
sudo pip install --upgrade pip
pip install wheel
sudo pip install numpy pandas
pip install sistr_cmd
```
Install instructions tested?

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

### roary
```
git clone https://github.com/sanger-pathogens/Roary.git
```
##### Ubuntu 14.04/16.04
All the dependancies can be installed using apt and cpanm. Root permissions are required. Ubuntu 16.04 contains a package for Roary but it is frozen at v3.6.0.
```bash
sudo apt-get install bedtools cd-hit ncbi-blast+ mcl parallel cpanminus prank mafft fasttree
sudo cpanm -f Bio::Roary
sudo apt-get install roary
Add the following lines to your $HOME/.bashrc file, or to /etc/profile.d/roary.sh to make it available to all users:
```
Install instructions tested?

### raxml

Install instructions tested?

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
"sudo" apt-get install docker-ce
```

##### Post-Docker-install steps to not have to use ‘sudo’ before every docker command
Pulled from here: https://docs.docker.com/install/linux/linux-postinstall/
```
sudo groupadd docker
sudo usermod -aG docker $USER
```
Log out and log back in (close & re-open terminal), so that your group membership is re-evaluated
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
Install instructions tested?

### Perlbrew (required for serotypefinder)
TO-DO: THESE COMMANDS NEED TO BE ADJUSTED - PROBABLY BETTER TO SOURCE .BASHRC 
```
curl -L https://install.perlbrew.pl | bash
nano ~/.profile
paste: source ~/perl5/perlbrew/etc/bashrc
. .profile
perlbrew --sudo install-cpanm
nano $HOME/.bash_vars
# add the following: export PERL5LIB=$PERL5LIB:/lib
```
Install instructions tested?

### BLAST+ Legacy (v2.2.26) for SerotypeFinder
```
# git clone files for blast-legacy from git repo containing dockerfile for serotypefinder
# move to /opt
# make sure that the blast executables are in the $PATH
which formatblastdb
# should result in:
/opt/blast-2.2.26/bin
```
Install instructions tested?

----------- END ------------------

--Everything below is from the image info google-doc, it may or may not work when installing using these directions---

### serotypefinder
Setting up SerotypeFinder
Go to wanted location for resfinder
`cd /path/to/some/dir`
Clone and enter the mlst directory
```
git clone https://bitbucket.org/genomicepidemiology/serotypefinder.git
cd plasmidfinder
```

Installing up the SerotypeFinder database
```
cd /path/to/serotypefinder
./INSTALL_DB database
```

Check all DB scripts works, and validate the database is correct
```
./UPDATE_DB database
./VALIDATE_DB database
```

Installing dependencies:
Perlbrew is used to manage isolated perl environments. To install it run:
`bash brew.sh`

This will installed Perl 5.23 in the Home folder, along with CPAN minus as package manager. Blast will also be installed when running brew.sh if BlastAll and FormatDB are not already installed and place in the user's path. After running brew.sh and installing Blast add this command to the end of your ~/bash_profile to add BlastAll and FormatDB to the user's path
export PATH=$PATH:blast-2.2.26/bin

If you want to download the two external tools from the Blast package, BlastAll and FormatDB, yourself go to
ftp://ftp.ncbi.nlm.nih.gov/blast/executables/release/LATEST

and download the version for your OS with the format:
blast-version-architecture-OS.tar.gz

after unzipping the file, add this command to the end of your ~/bash_profile.
export PATH=$PATH:/path/to/blast-folder/bin

where path/to/blast-folder is the folder you unzipped.
At last SerotypeFinder has several Perl dependencies. To install them (this requires CPAN minus as package manager):
make install

The scripts are self contained. You just have to copy them to where they should be used. Only the database folder needs to be updated manually.
Remember to add the program to your system path if you want to be able to invoke the program without calling the full path. If you don't do that you have to write the full path to the program when using it.



Linux (Ubuntu 16.04.3) Installation Commands for Programs

to the end of .bashrc:
. $HOME/.bash_vars


##### BLAST+
```
sudo apt-get update
sudo apt-get upgrade
sudo apt-get install build-essential
sudo apt-get install liblmdb-dev
mkdir ncbi-blast+
cd ncbi-blast+/
wget -N ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/2.6.0/ncbi-blast-2.6.0+-1.x86_64.rpm
sudo apt-get install alien
sudo alien -i ncbi-blast-2.6.0+-1.x86_64.rpm
```


### Lyve-set
```
cpanm File::Slurp
cpanm URI::Escape
sudo cpanm Bio::FeatureIO
sudo apt-get install libz-dev
sudo apt-get install unzip
sudo apt-get install libncurses5-dev
wget https://github.com/lskatz/lyve-SET/archive/v2.0.1.tar.gz
cd /opt/
mkdir Lyve-SET/
sudo tar -xvzf ~/v2.0.1.tar.gz
cd lyve-SET-2.0.1
sudo make install
cd /opt/Lyve-SET/lyve-SET-2.0.1/lib/samtools-1.3.1/htslib-1.3.1 
sudo make
```
Had to update the sym links manually:
```
cd /opt/Lyve-SET/lyve-SET-2.0.1/scripts
sudo ln -sfn /opt/Lyve-SET/lyve-SET-2.0.1/lib/bcftools-1.3.1/bcftools bcftools
sudo ln -sfn /opt/Lyve-SET/lyve-SET-2.0.1/lib/samtools-1.3.1/htslib-1.3.1/bgzip bgzip
sudo ln -sfn /opt/Lyve-SET/lyve-SET-2.0.1/lib/cg-pipeline/scripts/run_assembly_isFastqPE.pl run_assembly_isFastqPE.pl
sudo ln -sfn /opt/Lyve-SET/lyve-SET-2.0.1/lib/cg-pipeline/scripts/run_assembly_metrics.pl run_assembly_metrics.pl
sudo ln -sfn /opt/Lyve-SET/lyve-SET-2.0.1/lib/cg-pipeline/scripts/run_assembly_readMetrics.pl run_assembly_readMetrics.pl
sudo ln -sfn /opt/Lyve-SET/lyve-SET-2.0.1/lib/cg-pipeline/scripts/run_assembly_removeDuplicateReads.pl run_assembly_removeDuplicateReads.pl
sudo ln -sfn /opt/Lyve-SET/lyve-SET-2.0.1/lib/cg-pipeline/scripts/run_assembly_shuffleReads.pl run_assembly_shuffleReads.pl
sudo ln -sfn /opt/Lyve-SET/lyve-SET-2.0.1/lib/cg-pipeline/scripts/run_assembly_trimClean.pl run_assembly_trimClean.pl
sudo ln -sfn /opt/Lyve-SET/lyve-SET-2.0.1/lib/samtools-1.3.1/samtools samtools
sudo ln -sfn /opt/Lyve-SET/lyve-SET-2.0.1/lib/samtools-1.3.1/htslib-1.3.1/tabix tabix
sudo ln -sfn /opt/Lyve-SET/lyve-SET-2.0.1/lib/vcftools_0.1.12b/perl/vcf-sort vcf-sort
sudo ln -sfn /opt/Lyve-SET/lyve-SET-2.0.1/lib/bcftools-1.3.1/vcfutils.pl vcfutils.pl
sudo ln -sfn /opt/Lyve-SET/lyve-SET-2.0.1/lib/samtools-1.3.1/misc/wgsim wgsim
nano $HOME/.bash_vars
# add the following to .bash_vars: 
export PATH=/opt/Lyve-SET/lyve-SET-2.0.1/scripts:$PATH
```

### Jellyfish
```
cd downloads
wget https://github.com/gmarcais/Jellyfish/releases/download/v1.1.12/jellyfish-1.1.12.tar.gz
tar -xvzf jellyfish-1.1.12.tar.gz
cd jellyfish-1.1.12
./configure --prefix=/opt/
make -j 4
sudo make install
```

### Install mash/capnproto
```
cd downloads
git clone https://github.com/marbl/Mash.git
curl -O https://capnproto.org/capnproto-c++-0.6.1.tar.gz
tar -zxf capnproto-c++-0.6.1.tar.gz
cd capnproto-c++-0.6.1
./configure
make -j 6 check
sudo make install
sudo apt-get install libgsl-dev
sudo apt-get install libgsl2
sudo apt-get install autoconf
cd Mash
./bootstrap.sh
sudo ./configure --prefix=/opt/mash/
Sudo make
sudo make install
```

### Roary
```
git clone https://github.com/sanger-pathogens/Roary.git
sudo apt-get install bedtools cd-hit ncbi-blast+ mcl parallel cpanminus prank mafft fasttree
sudo cpanm -f Bio::Roary
cpanm LWP::Simple
cpanm Text::CSV
cpanm JSON
cpanm File::Slurp
```
