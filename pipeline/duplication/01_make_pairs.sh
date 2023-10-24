#!/usr/bin/bash -l
#SBATCH -p short -c 64 --mem 96gb --out logs/make_pairs.%a.log -a 1

# notes
# bp_mrtrans is part of bioperl, does a back translate of protein to CDS align templated by the CDS files
# kaks tools are part of https://github.com/hyphaltip/subopt-kaks
# lib/yn00_header.tsv  is just the header that comes out of on yn00_cds_prealigned

SAMPLES=samples.csv

CPUS=1
if [ $SLURM_CPUS_ON_NODE ]; then
    CPUS=$SLURM_CPUS_ON_NODE
fi

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

module load subopt-kaks
module load muscle
module load bioperl
module load workspace/scratch
module load parallel

IN=duplication
SEARCH=$IN/search
PAIRS=$IN/pairs
OUTKAKS=$IN/kaks
TEMP=$SCRATCH
mkdir -p $PAIRS $OUTKAKS lib


YN00=$(which yn00_cds_prealigned)
if [ ! -f $YN00 ]; then
    echo "need to have installed yn00_cds_prealigned - see https://github.com/hyphaltip/subopt-kaks"
    exit
fi

for file in $(ls ${SEARCH}/*.FASTA.tab.gz | sed -n ${N}p)
do
    perl scripts/make_pair_seqfiles.pl $file
    prefix=$(basename $file .FASTA.tab.gz)
    echo $prefix
    parallel -j $CPUS muscle -threads 2 -nt -align {} -output $TEMP/{/}.afa ::: $(ls ${PAIRS}/$prefix/*.pep)
    parallel -j $CPUS bp_mrtrans -i $TEMP/{/}.afa -if fasta -s {.}.cds -of fasta -o $TEMP/{/.}.cds.aln ::: $(ls $PAIRS/$prefix/*.pep)

    if [ ! -s lib/yn00_header.tsv  ]; then
        $YN00 $(ls $TEMP/*.cds.aln | sed -n 1p) | head -n 1 > lib/yn00_header.tsv
    fi
    # setup a single header for the results
    cp lib/yn00_header.tsv $OUTKAKS/$prefix.yn00.tab    
    $YN00 --noheader $TEMP/*.cds.aln | grep -v '^SEQ1' >> $OUTKAKS/$prefix.yn00.tab
done
