#!/usr/bin/bash -l
#SBATCH -p short -c 64 --mem 96gb --out logs/make_pairs_h1_h2.log 

# notes
# bp_mrtrans is part of bioperl, does a back translate of protein to CDS align templated by the CDS files
# kaks tools are part of https://github.com/hyphaltip/subopt-kaks
# lib/yn00_header.tsv  is just the header that comes out of on yn00_cds_prealigned

CPUS=1
if [ $SLURM_CPUS_ON_NODE ]; then
    CPUS=$SLURM_CPUS_ON_NODE
fi

module load subopt-kaks
module load muscle
module load bioperl
module load workspace/scratch
module load parallel

IN=duplication
SEARCH=$IN/search_h1_h2
PAIRS=$IN/pairs
OUTKAKS=$IN/kaks
TEMP=$SCRATCH
mkdir -p $PAIRS $OUTKAKS lib

YN00=$(which yn00_cds_prealigned)
if [ ! -f $YN00 ]; then
    echo "need to have installed yn00_cds_prealigned - see https://github.com/hyphaltip/subopt-kaks"
    exit
fi

file=$SEARCH/Trebouxia_sp._Hap2_h1-vs-h2.FASTA.tab.gz
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
