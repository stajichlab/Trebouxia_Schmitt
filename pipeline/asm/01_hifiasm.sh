#!/usr/bin/bash -l
#SBATCH -p epyc -N 1 -c 16 --mem 128gb --out logs/hifiasm.%a.log -a 1
module load hifiasm
IN=input/pacbio
OUT=asm/hifiasm
hostname
CPU=$SLURM_CPUS_ON_NODE
if [ -z $CPU ]; then
	CPU=2
fi
N=${SLURM_ARRAY_TASK_ID}

if [ -z $N ]; then
    N=$1
    if [ -z $N ]; then
        echo "Need an array id or cmdline val for the job"
        exit
    fi
fi


mkdir -p $OUT
IFS=,
SAMPLES=samples.csv

tail -n +2 $SAMPLES | sed -n ${N}p | while read BASE SPECIES STRAIN PACBIO ILLUMINA SUBPHYLUM PHYLUM LOCUS RNASEQ
do
    if [[ ! -f $OUT/$BASE.asm || $IN/$PACBIO -nt $OUT/$BASE.asm ]]; then
	    echo "hifiasm -o $OUT/$BASE.asm -t $CPU $IN/$PACBIO"
	    hifiasm -o $OUT/$BASE.asm -t $CPU $IN/$PACBIO
    fi
done
