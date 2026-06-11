#!/usr/bin/bash -l
#SBATCH -p short -c 128 --mem 96gb --out logs/run_ksd.log
CPU=1
if [ $SLURM_CPUS_ON_NODE ]; then
    CPU=$SLURM_CPUS_ON_NODE
fi

module load wgd
CDS=cds/Trebouxia_sp._Hap2.cds-transcripts.fa
NAME=$(basename $CDS)
wgd dmd $CDS 
wgd ksd wgd_dmd/$NAME.tsv $CDS -t $SCRATCH -n $CPU
