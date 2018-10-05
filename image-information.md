To do:
  * change serotypefinder install instructions to the ones I used for installing it into Docker
  * delete redundant sections
  * change order to reflect that of the type_pipe script
  * show location of various databases (Kraken, Mash, serotypefinder, etc.)

### Software/Tools used (in order they appear in type_pipe_X.X.sh)
| Software | Version | commands used (if not the name of the tool) |
| -------- | ------- | ------------------------------------------- |
| SRA-toolkit | x.x.x | `fastq-dump` |
| CG-pipeline/Lyve-SET | x.x.x | `run_assembly_shuffleReads.pl`, `run_assembly_trimClean.pl`, `run_assembly_readMetrics.pl` |
| Kraken | x.x.x | |
| SPAdes | x.x.x. | |
| QUAST | x.x.x | |
| Mash | x.x.x | |
| SerotypeFinder | x.x.x | |
| SeqSero | x.x.x | |
| ABRicate | x.x.x | |

### kraken
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
### mash
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

### prokka
```
git clone https://github.com/tseemann/prokka.git
```
##### Github - install from source code
Choose somewhere to put it, for example in your home directory (no root access required):
```bash
cd $HOME
```
Clone the latest version of the repository:
```bash
git clone https://github.com/tseemann/prokka.git
ls prokka
```
Index the sequence databases
```bash
prokka/bin/prokka --setupdb
```

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

### abricate
git clone https://github.com/tseemann/abricate.git

##### Source
If you install from source, Abricate has the following package dependencies:
* EMBOSS for `seqret`
* BLAST+ >2.3.0 for `blastn`, `makeblastdb`, `blastdbcmd`
* Decompression tools `gzip` and `unzip`
* Perl modules: `LWP::Simple`, `Text::CSV`, `Bio::Perl`, `JSON`, `File::Slurp`

These are easy to install on an Ubuntu-based system:
```bash
sudo apt-get install emboss bioperl ncbi-blast+ gzip unzip libjson-perl libtext-csv-perl libfile-slurp-perl liblwp-protocol-https-perl libwww-perl
git clone https://github.com/tseemann/abricate.git
./abricate/bin/abricate --check
./abricate/bin/abricate --setupdb
./abricate/bin/abricate ./abricate/test/assembly.fa
```

### seqsero
```bash
git clone https://github.com/denglab/SeqSero.git
sudo apt-get install python-biopython
```
python already at 2.7
bwa already installed
samtools already installed
did not install isPcr

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

##### Install perlbrew
```
curl -L https://install.perlbrew.pl | bash
nano ~/.profile
paste: source ~/perl5/perlbrew/etc/bashrc
. .profile
perlbrew --sudo install-cpanm
nano $HOME/.bash_vars
add the following: export PERL5LIB=$PERL5LIB:/lib
```

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

### Kraken
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

### Install Prokka
```
cd downloads
sudo apt-get install libdatetime-perl libxml-simple-perl libdigest-md5-perl git default-jre bioperl
git clone https://github.com/tseemann/prokka.git
cd prokka
bin/prokka --setupdb
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

### Install SeqSero
```
cd downloads
git clone https://github.com/denglab/SeqSero.git
sudo apt-get install python-biopython
nano $HOME/.bash_vars
add the following: export PATH=$PATH:/home/staphb/downloads/SeqSero
cd 
. .bash_vars
```

### Install Serotype Finder
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

### Install abricate
```
sudo apt-get install emboss bioperl gzip unzip libjson-perl libtext-csv-perl libfile-slurp-perl liblwp-protocol-https-perl libwww-perl
git clone https://github.com/tseemann/abricate.git
./abricate/bin/abricate --check
./abricate/bin/abricate --setupdb
./abricate/bin/abricate ./abricate/test/assembly.fa
nano $HOME/.bash_vars
add the following: export PATH=$PATH:/home/staphb/downloads/abricate/bin
cd 
. .bash_vars
```

### Install SISTR
```
sudo apt-get install python-pip python-dev build-essential 
sudo pip install --upgrade pip
pip install wheel
sudo pip install numpy pandas
pip install sistr_cmd
```

### Install Docker https://docs.docker.com/install/linux/docker-ce/ubuntu/#set-up-the-repository
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
