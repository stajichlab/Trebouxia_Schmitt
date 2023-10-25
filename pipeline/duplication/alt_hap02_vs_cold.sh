#!/bin/bash -l
#SBATCH -N 1 -n 1 -c 12 --mem 24G --out logs/duplication_hap02_cold.log -p epyc
module load fasta
module load workspace/scratch
CPU=1
if [ $SLURM_CPUS_ON_NODE ]; then
    CPU=$SLURM_CPUS_ON_NODE
fi

ANNOT=annotation
SAMPLES=samples.csv
OUT=duplication/search_hap02_cold
EVALUE=1e-15
CDS=cds
PEP=pep
mkdir -p $CDS $PEP $OUT
NAME=Trebouxia_sp._hap02_cold

if [ ! -s $OUT/$NAME.FASTA.tab.gz ]; then
	fasta36 -T $CPU -m 8c -E $EVALUE $PEP/Trebouxia_sp._Hap2.proteins.fa $PEP/Trebouxia_sp._ColdLineage.proteins.fa > $OUT/$NAME.FASTA.tab
	pigz $OUT/$NAME.FASTA.tab
fi
