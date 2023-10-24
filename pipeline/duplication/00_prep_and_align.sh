#!/bin/bash -l
#SBATCH -N 1 -n 1 -c 9 --mem 24G --out logs/duplication_prep.%a.log -a 1
module load fasta
module load workspace/scratch
CPU=1
if [ $SLURM_CPUS_ON_NODE ]; then
    CPU=$SLURM_CPUS_ON_NODE
fi

ANNOT=annotation
SAMPLES=samples.csv
OUT=duplication/search
EVALUE=1e-15
CDS=cds
PEP=pep
mkdir -p $CDS $PEP $OUT

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
tail -n +2 $SAMPLES | sed -n ${N}p | while read BASE SPECIES STRAIN PACBIO ILLUMINA SUBPHYLUM PHYLUM LOCUS RNASEQ
do
	NAME=$(echo -n "$SPECIES $STRAIN" | perl -p -e 's/\s+/_/g')
	echo "name is $NAME"
	rsync -a $ANNOT/$BASE/predict_results/$NAME.cds-transcripts.fa $CDS
	rsync -a $ANNOT/$BASE/predict_results/$NAME.proteins.fa $PEP
	if [ ! -s $OUT/$NAME.FASTA.tab.gz ]; then
		fasta36 -T $CPU -m 8c -E $EVALUE $PEP/$NAME.proteins.fa $PEP/$NAME.proteins.fa > $OUT/$NAME.FASTA.tab
		pigz $OUT/$NAME.FASTA.tab
	fi
done
