#!/bin/bash

# USAGE: sbatch ChIP_combinetagdirectories.sh <Name of Combined Directory> <genome> <link path> <tagdirectory1> <tagdirectory2> <tagdirectory3>

# 2019_08_12 Modified from 2019_07_10 ATAC_combinereplicates_new.sh to be adapted for ChIP-seq

# This script will take the tagdirectories and perform the following steps: 
    ## Combine tag directories
    ## Make an IGV file
    ## Convert the IGV file and make synthetic links
        
# Note, you need to be in the folder with the tag directories to run this script. 
    
# Use for ChIP-seq
    
# Please use the following slurm directives
        
#SBATCH -c 1                               # 1 core
#SBATCH -t 0-8:00                         # Runtime of 8 hours, in D-HH:MM format
#SBATCH -p short                           # Run in short partition
#SBATCH -o hostname_sinfo_%j.out           # File to which STDOUT + STDERR will be written, including job ID in filename
#SBATCH --mail-type=FAIL                    # Notifies when job ends or if job fails
#SBATCH --mail-user=lauren_wasson@hms.harvard.edu # Email to which notifications will be sent
#SBATCH --mem-per-cpu=10G
#SBATCH -e ChIP_combinetagdirectories.err

CombinedTagDirectory=`basename $1`

echo "Specifying genome"

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

#Load HOMER
module load homer/4.10.3

input=$1" -d "
shift 3
input=$input$@

#Combine Tag Directories
echo "Combining Tag Directories"
makeTagDirectory $input
echo "done"

#Make IGV files
echo "Making an IGV file for Combined Tag Directory"
makeUCSCfile ${CombinedTagDirectory} -o auto
echo "IGV file made"

#Move files around
#You're in the tagdirectories directory right now
mkdir -p ../IGVfiles/combinedIGVfiles
gzfile= ${CombinedTagDirectory}/*gz
mv $gzfile ../IGVfiles/combinedIGVfiles
echo "IGV file moved"

mkdir -p ../combinedtagdirectories
mv ${CombinedTagDirectory} ../combinedtagdirectories
echo "Tag directory moved"

echo "Loading IGV/IGV tools"
module load igv/2.4.9 igvtools/2.3.98

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

cd ../IGVfiles/combinedIGVfiles
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
