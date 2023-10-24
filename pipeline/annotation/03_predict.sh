#!/bin/bash -l
#SBATCH --nodes 1 --ntasks 24 --mem 64G -p intel --out logs/predict.%a.log -a 1 -p batch

module load funannotate
module load workspace/scratch
export FUNANNOTATE_DB=/bigdata/stajichlab/shared/lib/funannotate_db
#export AUGUSTUS_CONFIG_PATH=$(realpath lib/augustus/3.5/config)


which augustus
GMFOLDER=`dirname $(which gmhmme3)`
#genemark key is needed
if [ ! -f ~/.gm_key ]; then
	ln -s $GMFOLDER/.gm_key ~/.gm_key
fi

CPU=1
if [ $SLURM_CPUS_ON_NODE ]; then
    CPU=$SLURM_CPUS_ON_NODE
fi

INDIR=final_genomes
OUTDIR=annotation
SAMPLES=samples.csv
BUSCODB=chlorophyta_odb10
BUSCOSEED=Physcomitrium_patens
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
    GENOME=$INDIR/$BASE.masked.fasta
    funannotate predict --keep_no_stops --SeqCenter UCR -i $GENOME \
		-o $OUTDIR/$BASE -s "$SPECIES" --strain "$STRAIN"  \
		--cpus $CPU --min_training_models 50 --max_intronlen 1000 --name $LOCUS --optimize_augustus \
		--min_protlen 30 --tmpdir $SCRATCH  --busco_db $BUSCODB --busco_seed_species $BUSCOSEED \

done
