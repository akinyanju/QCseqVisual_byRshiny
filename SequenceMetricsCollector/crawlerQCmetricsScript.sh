#!/bin/bash

#SBATCH -p gt_compute
#SBATCH --cpus-per-task=1
#SBATCH -t 00:2:00
#SBATCH --mem=1G
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=raman.lawal@jax.org
#SBATCH --job-name=crawlerQCmetricsScript
#SBATCH --begin=now+10minutes
#SBATCH --output=/gt/data/seqdma/GTwebMetricsTables/.slurmlog/%x.%N.o%j.log

scriptDir="/gt/research_development/qifa/elion/software/qifa-ops/0.1.0"
slurmfileDir="/gt/data/seqdma/GTwebMetricsTables"

#resumbit gatherwebQCmetrics script to collect new update.
if [[ ! "$(squeue --format="%.18i %.9P %.30j %.8u %.8T %.10M %.9l %.6D %R"  | grep 'gatherwebQCmetrics')" ]] ; then
	sbatch $scriptDir/gatherwebQCmetrics.sh
fi

#
##remove slurm error/ouput file older than 24 hours
if [[ -d "$slurmfileDir/.slurmlog" ]]; then
  	find $slurmfileDir/.slurmlog -type f -mtime +1 -delete 
else
	mkdir $slurmfileDir/.slurmlog
fi
sbatch $0
