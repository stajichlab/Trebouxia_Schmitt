#!/usr/bin/bash -l
#SBATCH -p highmem -N 1 -n 1 -c 32 --mem 512gb --out logs/flye.%a.log -a 1
module load Flye
IN=input/pacbio
OUT=asm/flye
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

tail -n +2 $SAMPLES | sed -n ${N}p | while read BASE SPECIES STRAIN NANOPORE ILLUMINA SUBPHYLUM PHYLUM LOCUS RNASEQ
do
    if [[ ! -f $OUT/$BASE/assembly.fasta || $IN/$NANOPORE -nt $OUT/$BASE/assembly.fasta ]]; then
    	flye --pacbio-corr $IN/$NANOPORE --out-dir $OUT/$BASE --threads $CPU --scaffold
    fi
done
