#!/bin/bash

# USAGE: sbatch ChIP_manipulatebams.sh <basename of bamfile> <genome> <path to the www file folder>

#2018_06_29 Script created by Lauren Wasson
#2019_08_06 Script updated
	# Add command to make IGV files and links
	# added mm10 and hg38 as genome options
 
# This script will take the BAM files and perform the following steps: 
    ## Remove the reads with a quality score <20 
    ## Remove secondary alignments
    ## Only use reads from Chr1-Y (removes ChrM and GL reads)
    ## Make tag directories
    ## Make IGV files for this and synthetic links
    
# Use for ChIP-seq only
    
# Please use the following slurm directives
        
#SBATCH -c 1                               # 1 core
#SBATCH -t 0-8:00                         # Runtime of 1 hour, in D-HH:MM format
#SBATCH -p short                           # Run in short partition
#SBATCH -o hostname_sinfo_%j.out           # File to which STDOUT + STDERR will be written, including job ID in filename
#SBATCH --mail-type=FAIL                    # Notifies when job ends or if job fails
#SBATCH --mail-user=lauren_wasson@hms.harvard.edu # Email to which notifications will be sent
#SBATCH --mem-per-cpu=10G
#SBATCH -e ChIPmanipulatebams.err

bamFile=$1

echo "Manipulating Bams"

#Remove the reads with a quality score < 20
echo "Removing the reads with a quality score <20"
l=$(echo ${bamFile} | cut -d'.' -f1,2).q20.bam
samtools view -bhq 20 ${bamFile} > $l

#Remove secondary alignments
echo "Removing secondary alignments"
m=$(echo $l | cut -d'.' -f1,2).chr.bam
samtools view -bh -F 256 $l > $m
samtools index $m

#Only use reads from Chr1-Y (removes ChrM and GL reads)
echo "Removing Mitochondrial Reads"
n=$(echo $l | cut -d'.' -f1,2).ucsc.bam
samtools view -b $m chr1 chr2 chr3 chr4 chr5 chr6 chr7 chr8 chr9 chr10 chr11 chr12 chr13 chr14 chr15 chr16 chr17 chr18 chr19 chr20 chr21 chr22 chrX chrY > $n
samtools index $n

#Clean up the files
echo "cleaning up"
mv $l ../intermediatebams
mv $l.bai ../intermediatebams
mv $m ../intermediatebams
mv $m.bai ../intermediatebams
mv $n ../
mv $n.bai ../
rm -r ../intermediatebams

echo "Done Manipulating BAMS"

#Load HOMER
echo "Loading HOMER"
module load homer/4.10.3

#Create Tag directories
cd ../
echo "Creating Tag Directory for $n"

if [[ "$2" = "hg19" ]]; then
        echo "Using hg19"
        genome=hg19
elif [[ "$2" = "hg38" ]]; then
        echo "Using hg38"
        genome=hg38
elif [[ "$2" = "mm10" ]]; then
        echo "Using mm10"
        genome=mm10
else
        echo "Please load the correct genome"
fi

base=${bamFile%%.*}

makeTagDirectory $base $n -genome $genome -sspe 
echo "Done Creating Tag Directory"

mkdir -p ../tagdirectories
mv $base ../tagdirectories

#Make a file for IGV
echo "Making an IGV file"
cd ../tagdirectories
makeUCSCfile $base -o auto
echo "IGV file made" 

#Move the IGV file
mkdir -p ../IGVfiles
gzfile=${base}/*gz
mv $gzfile ../IGVfiles
echo "IGV file moved"

#IGV tools and links

echo "Loading IGV/IGV tools"
module load igv/2.4.9 igvtools/2.3.98

cd ../IGVfiles

if [[ "$2" = "hg19" ]]; then
        echo "Using hg19"
        genome2=/n/groups/seidman/lauren/hg19.genome
elif [[ "$2" = "hg38" ]]; then
        echo "Using hg38"
        genome2=/n/groups/seidman/lauren/hg38.genome
elif [[ "$2" = "mm10" ]]; then
        echo "Using mm10"
        genome2=mm10
else
        echo "Please load the correct genome"
fi

gz=${base}.ucsc.bedGraph.gz
l=${gz}.tdf
igvtools toTDF "$gz" "$l" "$genome2"

echo "Finished converting IGV file"

#Move them to the www file to make links to load into IGV on the desktop
mkdir -p $3
mv $l $3

cd $3

chmod 664 $l
seidman-url * > urls.txt
chmod 664 urls.txt

print seidman-url urls.txt
echo "Done"
