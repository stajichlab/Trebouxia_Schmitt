#!/usr/bin/bash -l
#SBATCH -p batch -N 1 -c 16 --mem 24gb --out logs/repeatmask.%a.log

module load RepeatModeler

CPU=1
if [ $SLURM_CPUS_ON_NODE ]; then
    CPU=$SLURM_CPUS_ON_NODE
fi

INDIR=final_genomes
MASKDIR=analysis/RepeatMasker
SAMPLES=samples.csv
RMLIBFOLDER=lib/repeat_library
PLANTLIB=lib/plant_repeats.lib
mkdir -p $RMLIBFOLDER
RMLIBFOLDER=$(realpath $RMLIBFOLDER)
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
    mkdir -p $MASKDIR/$BASE
    GENOME=$(realpath $INDIR)/$BASE.sorted.fasta
    FINAL=$(realpath $INDIR)/$BASE.masked.fasta
    if [ ! -s $MASKDIR/$BASE/$BASE.sorted.fasta.masked ]; then
	LIBRARY=$RMLIBFOLDER/$BASE.repeatmodeler.lib
	COMBOLIB=$RMLIBFOLDER/$BASE.combined.lib
	if [ ! -f $LIBRARY ]; then
		pushd $MASKDIR/$BASE
		BuildDatabase -name $BASE $GENOME
		RepeatModeler -pa $CPU -database $BASE -LTRStruct
		rsync -a RM_*/consensi.fa.classified $LIBRARY
		rsync -a RM_*/families-classified.stk $RMLIBFOLDER/$BASE.repeatmodeler.stk
		popd
	fi
	if [ ! -s $COMBOLIB ]; then
		cat $LIBRARY $PLANTLIB > $COMBOLIB
	fi
	if [[ -s $LIBRARY && -s $COMBOLIB ]]; then
	   module load RepeatMasker
	   RepeatMasker -e ncbi -xsmall -s -pa $CPU -lib $COMBOLIB -dir $MASKDIR/$BASE -gff $GENOME
	fi
    else
	echo "Skipping $BASE as masked file already exists"
   fi
   if [ ! -f $FINAL ]; then 
   	rsync -a $MASKDIR/$BASE/$BASE.sorted.fasta.masked $FINAL
   fi
done
