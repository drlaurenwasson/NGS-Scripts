#!/bin/bash

# USAGE: sbatch ChIP_peakcalls.sh <input_tag directory> <ChIP_tag_directory> <style> <genome>
#2019_08_06  Script created by Lauren Wasson

# This script will 
    ## Call peaks (taking into account "DNase" "histone" and "factor"
    ## run motifs on peaks 
# It comes from a keyfile but it doesnt necessarily have to.
# Run this script from tag directory folder    
# Please use the following slurm directives

#SBATCH -c 1                               # 1 core
#SBATCH -t 0-08:00                         # Runtime of 4 hour, in D-HH:MM format
#SBATCH -p short                           # Run in short partition
#SBATCH -o hostname_sinfo_%j.out           # File to which STDOUT + STDERR will be written, including job ID in filename
#SBATCH --mail-type=FAIL                    # Notifies when job ends or if job fails
#SBATCH --mail-user=lauren_wasson@hms.harvard.edu # Email to which notifications will be sent
#SBATCH --mem-per-cpu=8G
#SBATCH -e ChIP_peakcalls2.err

#To launch this script from the keyfile, use:
#while IFS=, read -r input chip style genome
#do
#sbatch /n/groups/seidman/lauren/ChIPseq/scripts/ChIP_peakcalls.sh ${input} ${chip} ${style} ${genome}
#done < keyfile.txt


#Load homer v 4.10
echo "Loading HOMER"
module load homer/4.10.3
#Call peaks
input=$1
chip=$2
style=$3
genome=$4
NAME=${chip}.regions.${style}.txt
findPeaks ${chip} -o ${NAME} -style ${style} -i ${input}

#run chiptxt-to-bed.pl script from Steve on peak files. This script sorts the HOMER output file by ch
romosome so it can be intersected with bed tools, but keeps the PEAK ID and peak score to be used in 
ChIP-Seeker.
echo "Manipulating Peak File"
chiptxt-to-bed.pl ${NAME}


#Call motifs
echo "Calling Motifs"
findMotifsGenome.pl ${NAME%.txt}.bed $4 ${NAME%.txt}_MOTIF -size 200 -preparsedDir .
echo "Done calling Motifs"

#Create a "Peak file" directory
mkdir -p ../peakcalls
mkdir -p ../peakcalls/txt
mkdir -p ../motifs
mv ${NAME%.txt}.bed ../peakcalls
mv $NAME ../peakcalls/txt
mv ${NAME%.txt}_MOTIF ../motifs

