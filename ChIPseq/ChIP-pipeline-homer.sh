#!/bin/bash

# USAGE: sbatch ChIP-pipeline.sh <what you want to name the directory> <Steve's Pathway to Bam Files> <genome> <pathway to urls> 

#2018_06_29 Script created
#2019_08_06 Updated to be more aligned with ATAC 
	# specify genome, make tdf files for IGV, add hg38 and mm10 to genome

# This script will take the BAM files and perform the following steps: 
    ## Make ChIP-seq directories based on whatever you want to name the directory
    ## Create Synthetic links to Steve's Bam Files
    ## Manipulate bam files by calling a new script 

# Please use the following slurm directives
        
#SBATCH -c 1                               # 1 core
#SBATCH -t 0-04:00                         # Runtime of 4 hours, in D-HH:MM format
#SBATCH -p short                           # Run in short partition
#SBATCH -o hostname_sinfo_%j.out           # File to which STDOUT + STDERR will be written, including job ID in filename
#SBATCH --mail-type=END,FAIL                    # Notifies when job ends or if job fails
#SBATCH --mail-user=lauren_wasson@hms.harvard.edu # Email to which notifications will be sent
#SBATCH --mem-per-cpu=8G
#SBATCH -e chip-pipeline.err

# Make Directories for current ChIP-seq files
echo "Making Directories"
DirectoryName=$1
mkdir -p ./$1
mkdir -p ./$1/bams
mkdir -p ./$1/bams/originals
mkdir -p ./$1/bams/intermediatebams

# Set paths
baseDir=/n/groups/seidman/lauren/ChIPseq/scripts
ChIPPath=$2
origbamsDir=/n/groups/seidman/lauren/ChIPseq/$1/bams/originals
bamDir=/n/groups/seidman/lauren/ChIPseq/$1/bams

#Create Synthetic Links
echo "Creating Synthetic Links"
cd $origbamsDir
for k in $ChIPPath/*
do
ln -s $k .
done

#Call the "ChIP_manipulatebams.sh" script to
    ## Remove the reads with a quality score <20 
    ## Remove secondary alignments
    ## Only use reads from Chr1-Y (removes ChrM and GL reads)
    ## Make Tag Directories
    ## Call Peaks

echo "Calling ChIP_manipulatebams.sh"
for f in *bam
do
sbatch $baseDir/ChIP_manipulatebams.sh $f $3 $4
done 
