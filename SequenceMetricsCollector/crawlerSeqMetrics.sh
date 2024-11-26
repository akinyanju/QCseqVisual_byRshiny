#!/bin/bash

#SBATCH -p gt_compute
#SBATCH --cpus-per-task=1
#SBATCH -t 00:2:00
#SBATCH --mem=1G
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=raman.lawal@jax.org
#SBATCH --job-name=crawlerSeqMetrics
#SBATCH --begin=now+10minutes
#SBATCH --output=/gt/data/seqdma/GTwebMetricsTables/SeqMetrics/.slurmlogSeqMet/%x.%N.o%j.log

scriptDir="/gt/research_development/qifa/elion/software/qifa-ops/0.1.0"
slurmfileDir="/gt/data/seqdma/GTwebMetricsTables/SeqMetrics"

if [[ ! "$(squeue --format="%.18i %.9P %.30j %.8u %.8T %.10M %.9l %.6D %R"  | grep 'gatherQuarterlyMetrics')" ]] ; then
	sbatch $scriptDir/gatherQuarterlyMetrics.sh
fi

sbatch $0
