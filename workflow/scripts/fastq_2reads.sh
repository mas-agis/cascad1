#!/bin/bash
#
#SBATCH -t 24:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=15G

#load modules
module load bioinfo/samtools/1.19

#getting the variables
PATH1="/work/project/CASCAD/mnaji/sm_folder/workflow"
PATH2="/work/project/CASCAD/mnaji/fastq_sr"

#change dir
cd $PATH1

#concatenate the fastq 
while read -r line ; do
	value1=$(echo "$line" | awk '{print $1}')
        value2=$(echo "$line" | cut -f7 | sed 's/,/ /g' )
	value3=$(echo "$line" | cut -f8 | sed 's/,/ /g' )
	cat $value2 > $PATH2/"$value1".R1.fq.gz
        cat $value3 > $PATH2/"$value1".R2.fq.gz
	echo "$value1" >> $PATH1/processed_fastq2reads.txt
done < temp

