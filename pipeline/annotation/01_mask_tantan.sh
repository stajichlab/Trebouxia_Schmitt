#!/usr/bin/bash -l
#SBATCH -p short -N 1 -n 1 -c 16 --mem 24gb --out logs/mask_tantan.%a.log
module load funannotate
CPU=1
if [ $SLURM_CPUS_ON_NODE ]; then
    CPU=$SLURM_CPUS_ON_NODE
fi

INDIR=final_genomes
SAMPLES=samples.csv
N=${SLURM_ARRAY_TASK_ID}

if [ -z $N ]; then
    N=$1
    if [ -z $N ]; then
        echo "need to provide a number by --array or cmdline"
        exit
    fi
fi
MAX=$(wc -l $SAMPLES | awk '{print $1}')
if [ $N -gt $MAX ]; then
    echo "$N is too big, only $MAX lines in $SAMPLES"
    exit
fi

IFS=,
tail -n +2 $SAMPLES | sed -n ${N}p | while read BASE SPECIES STRAIN NANOPORE ILLUMINA SUBPHYLUM PHYLUM LOCUS RNASEQ
do
    name=$BASE
    GENOME=$(realpath $INDIR)/$BASE.sorted.fasta
    FINAL=$(realpath $INDIR)/$BASE.masked.fasta
    if [ ! -f $FINAL ]; then 
	funannotate mask -i $GENOME -o $FINAL --cpus $CPU -m tantan
   fi
done
