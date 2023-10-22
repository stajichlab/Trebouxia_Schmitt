#!/usr/bin/bash -l
#SBATCH -p short --out logs/launch_canu_diploid.%a.log -a 1
module load canu
IN=input/pacbio
OUT=asm/canu_diploid
N=${SLURM_ARRAY_TASK_ID}
if [ -z $N ]; then
    N=$1
    if [ -z $N ]; then
	echo "no value for SLURM ARRAY - specify with -a or cmdline"
	exit
    fi
fi

mkdir -p $OUT
IFS=,
SAMPLES=samples.csv

tail -n +2 $SAMPLES | sed -n ${N}p | while read BASE SPECIES STRAIN PACBIO ILLUMINA SUBPHYLUM PHYLUM LOCUS RNASEQ
do
    canu -p ${BASE} -d $OUT/${BASE} corOutCoverage=200 batOptions="-dg 3 -db 3 -dr 1 -ca 500 -cp 50" genomeSize=200m -pacbio $IN/$PACBIO gridOptions="-p epyc"
done
