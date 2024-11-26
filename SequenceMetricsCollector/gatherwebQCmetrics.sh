#!/usr/bin/env bash

#SBATCH -p gt_compute
#SBATCH --cpus-per-task=1
#SBATCH -t 8:00:00
#SBATCH --mem=4G
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=raman.lawal@jax.org
#SBATCH --job-name=gatherwebQCmetrics
#SBATCH --output=/gt/data/seqdma/GTwebMetricsTables/.slurmlog/%x.%N.o%j.log
#SBATCH --array=1-14

module use --append /gt/research_development/qifa/elion/modulefiles
module load node/8.6.0

############################Key Paths
Email="akinyanju.lawal@jax.org"
OUT="/gt/data/seqdma/GTwebMetricsTables"
QCdir_nonarchive="/gt/data/seqdma/qifa"
QCdir_archive="/gt/data/seqdma/.qifa.qc-archive"
export SETJSONFILE=".settings.json"
export RunInfo="RunInfo.xml"
qifaPipelineDir="/gt/research_development/qifa/elion/software/qifa-ops/0.1.0"
################################################################################################################
set -E
set -o functrace
function failed_command {
    local retval=$?
    local line=${last_lineno:-$1}
    echo "Offending command @ line $line: $BASH_COMMAND" > $OUT/.logfile
    #echo "Trace: " "$@"
    #exit $retval
}
if (( ${BASH_VERSION%%.*} <= 3 )) || [[ ${BASH_VERSION%.*} = 4.0 ]]; then
        trap '[[ $FUNCNAME = handle_error ]] || { last_lineno=$real_lineno; real_lineno=$LINENO; }' DEBUG
fi

init_command() {
  check_list_temp_script
  whitelist_QCdir
  update_ProjDir_list
  database_backup_cleanup
  database
  bailout_noupdate
}

####################################################################################
####To do
	#Implement auto adding user to user database - chgrp genometech .userdatabase
		#chmod -R 773 .userdatabase
#add permission chmod +rwx
#create folder for database user informatino

############################
function check_list_temp_script {
  if [[ ! -f "/gt/research_development/qifa/elion/software/qifa-ops/0.1.0/qifa-qc-scripts/pipelinelist/pipelinelist.txt" ]]; then
    echo ''
	  echo -e 'ERROR: Missing /gt/research_development/qifa/elion/software/qifa-ops/0.1.0/qifa-qc-scripts/pipelinelist/pipelinelist.txt 
    pipelinelist.txt contains, one per line, list of pipelines e.g. atacseq, rnaseq etc \n Metrics update aborted!' \
    | mail -s "GT interface missing pipeline list" $Email
	  exit 1;
  else
	  Application=$(head -n $SLURM_ARRAY_TASK_ID $qifaPipelineDir/qifa-qc-scripts/pipelinelist/pipelinelist.txt | tail -n 1)
  fi
  if [[ ! -f "$qifaPipelineDir/gatherApplicationMetrics.js" ]]; then
	  echo ''
	  echo -e 'ERROR: Missing '$qifaPipelineDir/gatherApplicationMetrics.js' \n Program aborted!' \
    | mail -s "GT interface missing gatherApplicationMetrics.js" $Email
	  echo ''
	  exit 1;
  elif [[ ! -f "$qifaPipelineDir/qifa-qc-scripts/$Application/$Application.pe.report.database.template" ]]; then
	  echo ''
	  echo -e 'ERROR: Missing '$qifaPipelineDir/qifa-qc-scripts/$Application/$Application.pe.report.database.template' \n Program aborted!' \
    | mail -s "GT interface missing template" $Email
	  echo ''
	  exit 1;
  else
	  echo ''
  fi
}

############################
############################
###1
#Once metrics is collected from .qifa.qc-archive, the directory should now be skipped for the next 45 days.
#New metrics will be regularly searched within the qifa directory to be updated in the database...
#The limitation of this approach is that if project in qifa directory does not have "package" and "release" signatures, it will not be collected.
#The reason is that, current qc automation process from demux to secondary analysis makes is difficult for this script to differentiatte between qc folders
#awaiting processing and that which was processed but not-delivered. Both cases will not have "package" and "release" signatures in .settings.
#Therefore, script will continuously crawl qifa directory to collect metrics with these two signatures.
#Processed but non-delivery folder will be archived. If this happens, the script will collect metric from such folder on 45th day after the last crawl
#within .qifa.qc-archive directory. This means, QC from genuine non-delivered folder will wait 45 days to be collected. 

####2.
#To speed metrics processing, script will only collect data from new qc folder. To do this...
#a file <*QCDir_nonarchive.update.txt> is created to hold list of previous directories from which metrics where collected, up to 30 days...
#Every time the script crawl qifa directory, it then compare list of all current folders <*.QCDir_nonarchive.txt> to list of folders previously collected...
#New qc folder is then passed along the rest of the code. 
  ####Note that the later part of the code can determine when folder is created from demux but qc processes is yet performed. In this case,
  ####such directory will be recollected in next round of crawling.
function whitelist_QCdir {
  if [[ -s "$OUT/.$Application.QCDir_archive.update_day_start.txt" ]]; then
    day_30_start=`cat $OUT/.$Application.QCDir_archive.update_day_start.txt`
  else
    day_30_start=$(date +"%Y-%m-%d")
  fi
  ##
  ##
  day_present=$(date +"%Y-%m-%d")
  day_30_countdown=$(echo "( `date -d $day_present +%s` - `date -d $day_30_start +%s`) / (24*3600)" | bc)
  ##
  ##On or after every 30 days, search archival folder to update the QC metrics database
  if [[ "$day_30_countdown" -ge 30 ]]; then
    DirList=`find $QCdir_archive -type d -name "$Application"`
    date +"%Y-%m-%d" > $OUT/.$Application.QCDir_archive.update_day_start.txt
  elif [[ -s "$OUT/$Application.metrics.txt" ]]; then 
    if [[ -f "$OUT/.$Application.QCDir_nonarchive.txt" ]]; then
      cat $OUT/.$Application.QCDir_nonarchive.txt >> $OUT/.$Application.QCDir_nonarchive.update.txt
      awk '!seen[$0]++' $OUT/.$Application.QCDir_nonarchive.update.txt > $OUT/.tmp.QCDir_nonarchive.$Application
      mv $OUT/.tmp.QCDir_nonarchive.$Application $OUT/.$Application.QCDir_nonarchive.update.txt
      find $QCdir_nonarchive -type d -name "$Application" > $OUT/.$Application.QCDir_nonarchive.txt 
      #extract only the new QC folder
      grep -vf $OUT/.$Application.QCDir_nonarchive.update.txt $OUT/.$Application.QCDir_nonarchive.txt > $OUT/.DirList.$Application
      mv $OUT/.DirList.$Application $OUT/.$Application.QCDir_nonarchive.txt
      DirList=`cat $OUT/.$Application.QCDir_nonarchive.txt`
    else
      find $QCdir_nonarchive -type d -name "$Application" > $OUT/.$Application.QCDir_nonarchive.txt
      DirList=`cat $OUT/.$Application.QCDir_nonarchive.txt`
    fi
  else
    DirList=`find $QCdir_nonarchive $QCdir_archive -type d -name "$Application"`
    date +"%Y-%m-%d" > $OUT/.$Application.QCDir_archive.update_day_start.txt
    touch $OUT/.$Application.activate_pulling_NULL_metrics_archive.txt #file temporary created to pull NULL metrics. deleted later in code
    find $QCdir_nonarchive -type d -name "$Application" > $OUT/.$Application.QCDir_nonarchive.txt
  fi
####reset *.QCDir_nonarchive.update.txt after 10 days of holding QC directory list
if [[ -s "$OUT/.$Application.QCDir_nonarchive.update.reset_day_start.txt" ]]; then
  day_10_start=`cat $OUT/.$Application.QCDir_nonarchive.update.reset_day_start.txt`
  day_10_end=$(date +"%Y-%m-%d")
  day_10_countdown=$(echo "( `date -d $day_10_end +%s` - `date -d $day_10_start +%s`) / (24*3600)" | bc)
  if [[ "$day_10_countdown" -ge 10 ]] ; then
    > $OUT/.$Application.QCDir_nonarchive.update.txt
    date +"%Y-%m-%d" > $OUT/.$Application.QCDir_nonarchive.update.reset_day_start.txt
  fi
else
  date +"%Y-%m-%d" > $OUT/.$Application.QCDir_nonarchive.update.reset_day_start.txt
fi
}

############################
#Metrics are pulled from QC delivery folder. If multiple pipelines are initiated for a single project within the QC folder...
	#we should collect metrics only for the intended application (primary). i.e. if QC has metrics from wgs (primary) and rnaseq (secondary)...
	#only wgs metrics should ne collect
function update_ProjDir_list {
#To Do: #PDX-WES AND Amplicon respective application
ProjDirs=""
ProjCount=`echo -en "$DirList\n" | wc -l`
for n in $(seq 1 $ProjCount); do
	ProjList=`echo -en "$DirList\n" | head -n $n | tail -n1`
    ProjDir_list="${ProjList%/*}"
	if [[ -f "$ProjDir_list/$SETJSONFILE" ]] ; then
    	projectApplication=$(grep '"application":' $ProjDir_list/$SETJSONFILE | awk '{print $2}' | grep -o '".*"' | sed 's/"//g')
		if [[ -n "$projectApplication" ]] ; then
    		if [[ "$Application" == "atacseq" ]] && [[ ,ATACSeq,ATAC, == *,$projectApplication,*  ]] && [[ -d "$ProjDir_list/$Application" ]] ; then
            	ProjDirs+=$(echo -n "$ProjDir_list\n")
	 		elif [[ "$Application" == "chic" ]] && [[ ,Other, == *,$projectApplication,*  ]] && [[ -d "$ProjDir_list/$Application" ]]; then
           		ProjDirs+=$(echo -n "$ProjDir_list\n")
	 		elif [[ "$Application" == "ctp" ]] && [[ ,PDX-WGS, == *,$projectApplication,*  ]] && [[ -d "$ProjDir_list/$Application" ]] ; then
           		ProjDirs+=$(echo -n "$ProjDir_list\n")
	 		elif [[ "$Application" == "pdxrnaseqR2" ]] && [[ ,cellranger, == *,$projectApplication,*  ]] && [[ -d "$ProjDir_list/$Application" ]] ; then
           		ProjDirs+=$(echo -n "$ProjDir_list\n")
	 		elif [[ "$Application" == "rnaseq" ]] && [[ ,mRNA,Total-RNA, == *,$projectApplication,*  ]] && [[ -d "$ProjDir_list/$Application" ]] ; then
           		ProjDirs+=$(echo -n "$ProjDir_list\n")
	 		elif [[ "$Application" == "rrbs" ]] && [[ ,RRBS, == *,$projectApplication,*  ]] && [[ -d "$ProjDir_list/$Application" ]] ; then
           		ProjDirs+=$(echo -n "$ProjDir_list\n")
	 		elif [[ "$Application" == "wgbs" ]] && [[ ,WGBS, == *,$projectApplication,*  ]] && [[ -d "$ProjDir_list/$Application" ]] ; then
           		ProjDirs+=$(echo -n "$ProjDir_list\n")
	 		elif [[ "$Application" == "chipseq" ]] && [[ ,ChiP,ChIPSeq, == *,$projectApplication,*  ]] && [[ -d "$ProjDir_list/$Application" ]] ; then
           		ProjDirs+=$(echo -n "$ProjDir_list\n")
	 		elif [[ "$Application" == "pdxrnaseq" ]] && [[ ,PDX-mRNA,pdxrnaseq, == *,$projectApplication,*  ]] && [[ -d "$ProjDir_list/$Application" ]] ; then
           		ProjDirs+=$(echo -n "$ProjDir_list\n")
	 		elif [[ "$Application" == "pdxwgs" ]] && [[ ,PDX-WGS, == *,$projectApplication,*  ]] && [[ -d "$ProjDir_list/$Application" ]] ; then
           		ProjDirs+=$(echo -n "$ProjDir_list\n")
	 		elif [[ "$Application" == "rnaseqR2" ]] && [[ ,cellranger, == *,$projectApplication,*  ]] && [[ -d "$ProjDir_list/$Application" ]] ; then
           		ProjDirs+=$(echo -n "$ProjDir_list\n")
	 		elif [[ "$Application" == "wes" ]] && [[ ,WES, == *,$projectApplication,*  ]] && [[ -d "$ProjDir_list/$Application" ]] ; then
           		ProjDirs+=$(echo -n "$ProjDir_list\n")
	 		elif [[ "$Application" == "wgs" ]] && [[ ,WGS,ChIA-PET, == *,$projectApplication,*  ]] && [[ -d "$ProjDir_list/$Application" ]] ; then
        		ProjDirs+=$(echo -n "$ProjDir_list\n")
			elif [[ "$Application" == "basic" ]] && [[ ,Amplicon,Other, == *,$projectApplication,*  ]] && [[ -d "$ProjDir_list/$Application" ]] ; then
        		ProjDirs+=$(echo -n "$ProjDir_list\n")
    		fi
		fi
	fi
done
ProjTotal=`echo -en "$ProjDirs" | wc -l`
#update the directory non-archival 
echo -en "$ProjDirs" > $OUT/.$Application.QCDir_nonarchive.txt
#If total project is 0, then empty $OUT/.$Application.QCDir_nonarchive.txt and exit script
if [[ "$(echo -en "$ProjDirs" | wc -l)" == 0 ]]; then
  	exit;
fi
}
#################################
#Create backup that gets deleted every 10 days before generating new table. If problem exit with $OUT/$Application.metrics.txt, then we can revert to 
#most recently generated backup. 
function database_backup_cleanup {
if [[ -d "$OUT/.GTmetricsbackup" ]] && [[ -f "$OUT/$Application.metrics.txt" ]]; then
  cp $OUT/$Application.metrics.txt $OUT/.GTmetricsbackup/.$Application.metrics.$day_present.txt
  find $OUT/.GTmetricsbackup -type f -mtime +10 -delete
  if [[ -d "$OUT/.slurmlog" ]]; then
  	find $OUT/.slurmlog -type f -mtime +1 -delete #remove slurm error/ouput file in 24 hours
  else
	mkdir $OUT/.slurmlog
  fi
else 
  mkdir $OUT/.GTmetricsbackup
  touch $OUT/.GTmetricsbackup/.$Application.metrics.$day_present.txt
fi
}
#################################

function QCdelivery_check_status {
  if [[ -f "$ProjDir/$SETJSONFILE" ]]; then
		if grep -q "projectId" $ProjDir/$SETJSONFILE ; then
			projectId=$(grep projectId $ProjDir/$SETJSONFILE | awk '{print $2}' | grep -o '".*"' | sed 's/"//g');
		else
			projectId="NULL"
			#echo -e 'WARNING: missing some informaton in '$SETJSONFILE'. Project_ID column will be set to "NULL" in database'			
		fi
		if grep -q "projectFinal" $ProjDir/$SETJSONFILE; then
			projectFinal=$(grep projectFinal $ProjDir/$SETJSONFILE | awk '{print $2}' | grep -o '".*"' | sed 's/"//g');
		else
			projectFinal="NULL"
			#echo -e 'WARNING: missing some informaton in '$SETJSONFILE'. Project_run_type column will be set to "NULL" in database';
		fi
		if grep -q "deliveryFolder" $ProjDir/$SETJSONFILE; then
			if [[ "$(grep -q "deliveryFolder" $ProjDir/$SETJSONFILE | awk '{print $2}' | grep -o '".*"' | sed 's/"//g')" == "NULL" ]]; then
				deliveryfolder="NULL"
			else
				deliveryfolder=$(grep deliveryFolder $ProjDir/$SETJSONFILE | awk '{print $2}' | grep -o '".*"' | sed 's/"//g' | awk -F/ '{print $4}');
			fi
		else
			deliveryfolder="NULL"
			#echo -e 'WARNING: missing some informaton in '$SETJSONFILE'. Investigator_Folder column will be set to "NULL" in database';
		fi
    #qifa-qc release command must be initiated to collect the release date. qifa-qc package will create packageTimestamp but it is deceiving to 
    #annotate a metrics as delivered based on packageTimestamp signature because the project is accutaly not released
		if grep -q "releaseDate" $ProjDir/$SETJSONFILE ; then
			Timestamp=$(grep releaseDate $ProjDir/$SETJSONFILE | awk '{print $2}' | grep -o '".*"' | sed 's/"//g');
			releaseDate=$(date -d $Timestamp +'%Y-%m-%d'); #this reformat the date from 20110130 to 2011-01-30
		#elif grep -q "packageTimestamp" $ProjDir/$SETJSONFILE ; then
		#	Timestamp=$(grep -w packageTimestamp $ProjDir/$SETJSONFILE | awk '{print $2}' | grep -o '".*"' | sed 's/"//g');
		#	releaseDate=${Timestamp%T*}
		else
			releaseDate="NULL"
			#echo -e 'WARNING: missing some informaton in "$SETJSONFILE". Release_Date column will be set to "NULL" in database';
		fi
	else
		projectId="NULL"
		projectFinal="NULL"
		deliveryfolder="NULL"
		releaseDate="NULL"
		echo -e 'WARNING: missing '$SETJSONFILE' file @ '$ProjDir'.\nSome columns will be set to "NULL" in database';
	fi
}
###
###
	######if no delivery, then purge the QC folder whitelist so that QC can be recollected once delivery occured
function QCdir_updatelist {
	if [[ "$deliveryfolder" == "NULL" ]] || [[ "$releaseDate" == "NULL" ]] ; then
		if [[ "$(grep $ProjDir $OUT/.$Application.QCDir_nonarchive.txt)" ]]; then
      		grep -v "$ProjDir" $OUT/.$Application.QCDir_nonarchive.txt > $OUT/.$Application.QCDir_nonarchive.tmp.txt
      		mv $OUT/.$Application.QCDir_nonarchive.tmp.txt $OUT/.$Application.QCDir_nonarchive.txt
      		continue;
    	fi
  	fi
	}

###
#######################
###
###
###
function gather_metrics_js {
	if [[ $Application == "basic" ]] ; then
		$qifaPipelineDir/gatherApplicationMetrics.js getmetrics \
		-p $ProjDir \
		-q basic \
		-r $qifaPipelineDir/qifa-qc-scripts/$Application/$Application.pe.report.database.template \
		-o $OUT/"$projectId"_QCreport.$Application.csv 2>&1> $OUT/"$projectId"_QCreport.$Application.log
		col_total=$(head -n1 $OUT/"$projectId"_QCreport.$Application.csv | tr ',' '\n' | nl | wc -l) #if organism is other, update unfilled col with NULL
		cat $OUT/"$projectId"_QCreport.$Application.csv  \
		| awk -F'"' -v OFS='' '{ for (i=2; i<=NF; i+=2) gsub(",", "", $i) } 1'  \
		| tr ',' '\t' | awk -F'\t' -v OFS='\t' -v N="$col_total" '{while(colNr++<N){$colNr=($colNr==""?"NULL":$colNr)}colNr=0}1' | \
		sed ':a;/^[ \n]*$/{$d;N;ba}; 1s/^/Lane\t/; 2,$s|^|'$Lane'\t|g; 1s/^/FlowcellID\t/; 2,$s|^|'$FlowcellID'\t|g; 1s/^/InstrumentID\t/; 2,$s|^|'$InstrumentID'\t|g;
		1s/^/RunID\t/; 2,$s|^|'$RunID'\t|g; 1s/^/Release_Date\t/; 2,$s|^|'$releaseDate'\t|g; 1s/^/Project_run_type\t/; 2,$s|^|'$projectFinal'\t|g; 
		1s/^/Project_ID\t/; 2,$s|^|'$projectId'\t|g; 1s/^/Investigator_Folder\t/; 2,$s|^|'$deliveryfolder'\t|g; 1s/$/\tCluster_PF_PCT/; 2,$s|$|\t'$Cluster_PF'|g;
		1s/$/\tCluster_PF_SD_PCT/; 2,$s|$|\t'$Cluster_PF_SD'|g; 1s/$/\tReads_Cluster_number_Mb/; 2,$s|$|\t'$Reads'|g; 1s/$/\tReads_Cluster_number_PF_Mb/; 2,$s|$|\t'$Reads_PF'|g;
		1s/$/\tQ30_or_higher_PCT/; 2,$s|$|\t'$Percent_Q30'|g; 1s/$/\tYield_Gb/; 2,$s|$|\t'$Yield'|g; 1s/$/\tAligned_PhiX_PCT/; 2,$s|$|\t'$Aligned'|g; 1s/$/\tAligned_PhiX_SD_PCT/; 2,$s|$|\t'$Aligned_SD'|g;
		1s/$/\tError_rate_PhiX_alignment/ ; 2,$s|$|\t'$Error'|g; 1s/$/\tError_rate_PhiX_alignment_SD/ ; 2,$s|$|\t'$Error_SD'|g; 1s/$/\tProjStatus/; 2,$s|$|\t'NULL'|g' \
		| sed '1d' | awk -F'\t' 'BEGIN {OFS = FS} {sub(/.*GT/,"GT",$5); print}' | awk -F'\t' '!(($5=="NULL") && ($6=="NULL"))'
	else
		$qifaPipelineDir/gatherApplicationMetrics.js getmetrics \
		-p $ProjDir \
		-q basic,$Application \
		-r $qifaPipelineDir/qifa-qc-scripts/$Application/$Application.pe.report.database.template \
		-o $OUT/"$projectId"_QCreport.$Application.csv 2>&1> $OUT/"$projectId"_QCreport.$Application.log
		col_total=$(head -n1 $OUT/"$projectId"_QCreport.$Application.csv | tr ',' '\n' | nl | wc -l) #if organism is other, update unfilled col with NULL
		cat $OUT/"$projectId"_QCreport.$Application.csv  \
		| awk -F'"' -v OFS='' '{ for (i=2; i<=NF; i+=2) gsub(",", "", $i) } 1'  \
		| tr ',' '\t' | awk -F'\t' -v OFS='\t' -v N="$col_total" '{while(colNr++<N){$colNr=($colNr==""?"NULL":$colNr)}colNr=0}1' | \
		sed ':a;/^[ \n]*$/{$d;N;ba}; 1s/^/Lane\t/; 2,$s|^|'$Lane'\t|g; 1s/^/FlowcellID\t/; 2,$s|^|'$FlowcellID'\t|g; 1s/^/InstrumentID\t/; 2,$s|^|'$InstrumentID'\t|g;
		1s/^/RunID\t/; 2,$s|^|'$RunID'\t|g; 1s/^/Release_Date\t/; 2,$s|^|'$releaseDate'\t|g; 1s/^/Project_run_type\t/; 2,$s|^|'$projectFinal'\t|g; 
		1s/^/Project_ID\t/; 2,$s|^|'$projectId'\t|g; 1s/^/Investigator_Folder\t/; 2,$s|^|'$deliveryfolder'\t|g; 1s/$/\tCluster_PF_PCT/; 2,$s|$|\t'$Cluster_PF'|g;
		1s/$/\tCluster_PF_SD_PCT/; 2,$s|$|\t'$Cluster_PF_SD'|g; 1s/$/\tReads_Cluster_number_Mb/; 2,$s|$|\t'$Reads'|g; 1s/$/\tReads_Cluster_number_PF_Mb/; 2,$s|$|\t'$Reads_PF'|g;
		1s/$/\tQ30_or_higher_PCT/; 2,$s|$|\t'$Percent_Q30'|g; 1s/$/\tYield_Gb/; 2,$s|$|\t'$Yield'|g; 1s/$/\tAligned_PhiX_PCT/; 2,$s|$|\t'$Aligned'|g; 1s/$/\tAligned_PhiX_SD_PCT/; 2,$s|$|\t'$Aligned_SD'|g;
		1s/$/\tError_rate_PhiX_alignment/ ; 2,$s|$|\t'$Error'|g; 1s/$/\tError_rate_PhiX_alignment_SD/ ; 2,$s|$|\t'$Error_SD'|g; 1s/$/\tProjStatus/; 2,$s|$|\t'NULL'|g' \
		| sed '1d' | awk -F'\t' 'BEGIN {OFS = FS} {sub(/.*GT/,"GT",$5); print}' | awk -F'\t' '!(($5=="NULL") && ($6=="NULL"))'
	fi
}
###
###
###
###

function database {
  #echo -e 'INFO: A total of '$ProjTotal' Project(s) is/are found'
  #if [[ -f "$OUT/$Application.metrics.txt" ]] ; then
	  #echo -e 'INFO: Checking for an existing '$Application' metrics database @ ....<mention the directory>'
	  #echo -e 'INFO: '$Application' metrics database is found @ ....<mention the directory>'
	  #echo -e 'INFO: '$Application' metrics database will be updated, if not already present, with '$ProjTotal' new projects'
	  #echo -e 'INFO: Duplicate sample metrics, if present, will be excluded'
    #echo ''
  #else
	  #echo -e 'INFO: No existing metrics database for '$Application' found @ ....<mention the directory>'
	  #echo -e 'INFO: A new '$Application' metrics database will be created'
	  #echo -e 'INFO: Location of newly created metrics database is ....<mention the directory>'
    #echo ''
  #fi
  ############################
  #create database
  for n in $(seq 1 $ProjTotal); do
	  ProjDir=`echo -en "$ProjDirs\n" | head -n $n | tail -n1`
    ###Skip qc folder with non "package" or "release" signature as they may not have been processed. This way, the folder can be re-checked later
    ###However, collect metrics from such folder if the directory is in .qifa.qc-archive, determinable by day_30_countdown
    if [[ -f "$OUT/.$Application.activate_pulling_NULL_metrics_archive.txt" ]] ; then
      QCdelivery_check_status
    elif [[ "$day_30_countdown" -ge 30 ]] ; then
      QCdelivery_check_status
    else
      QCdelivery_check_status
	  QCdir_updatelist #this mitigate against adding unprocessed qcdir to list of processed qcdir
    fi
	  #Determine location of Run_Metrics_Summary, select the originial file *draft* first, if present.
	  if [[ "$(ls $ProjDir 2> /dev/null | grep "Run_Metric_Summary" | grep "draft")" ]] ; then
		  export RunMetricsSummary=$ProjDir/$(ls $ProjDir | grep "Run_Metric_Summary" | grep "draft")
	  elif [[ "$(ls $ProjDir 2> /dev/null | grep "Run_Metric_Summary.csv")" ]] ; then
		  export RunMetricsSummary=$ProjDir/$(ls $ProjDir | grep "Run_Metric_Summary.csv")
	  elif [[ "$(ls $ProjDir/package 2> /dev/null | grep "Run_Metric_Summary" | grep "draft")" ]] ; then
		  export RunMetricsSummary=$ProjDir/package/$(ls $ProjDir/package | grep "Run_Metric_Summary" | grep "draft")
	  elif [[ "$(ls $ProjDir/package 2> /dev/null | grep "Run_Metric_Summary.csv")" ]] ; then
		  export RunMetricsSummary=$ProjDir/package/$(ls $ProjDir | grep "Run_Metric_Summary.csv")
	  else
		  export RunMetricsSummary=""
	  fi
      #Gather metrics for each project from $ProjDir/$RunMetricsSummary and and .json files
	  if [[ ! -z "$RunMetricsSummary" ]] ; then
		  InstrumentID=$(grep -A1 "FlowCellID" $RunMetricsSummary | tr ',' '\t' | sed 's+"++g' | \
		  awk 'NR == 1{ for(i=1; i<=NF; i++) if ($i == "MachineID") { pos = i; break } } NR == 2{ print $pos; exit }')
		  FlowcellID=$(grep -A1 "FlowCellID" $RunMetricsSummary | tr ',' '\t' | sed 's+"++g' | \
		  awk 'NR == 1{ for(i=1; i<=NF; i++) if ($i == "FlowCellID") { pos = i; break } } NR == 2{ print $pos; exit }')
		  RunID=$(grep "Run Id" $ProjDir/RunInfo.xml | sed 's/=/\t/g' | awk '{print $3}' | sed 's/"//g');
		  ################################
		  #Note that for ease of - and to accurately subset columns, spaces in "strings" in $ColumnNamesSubset have been removed. E.g. Cluster PF not ClusterPF and Reads PF now ReadsPF
		  ColumnNamesSubset='Lane|ClusterPF|Reads|ReadsPF|%>=Q30|Yield|Error|Aligned'
		  #The string "Cluster PF", found in the header of the field of interest, was used to extract lines for field of interest. Other unique string could also be used as long as it occures 
		  #only in the header of column to subset. Then extract only the interested column number based on column name, subject to the $ColumnNamesSubset
		  #This approach ensures that if the column number for the $ColumnNamesSubset changes in the future, the script will still be able to select the correct column
		  LaneMetColNum=$(cat $RunMetricsSummary | grep -A$(sed -n '/Cluster PF/,$p' $RunMetricsSummary | wc -l) "Cluster PF" | sed -n '/Read 2 (I)/q;p' | tr ',' '\t' \
		  | awk 'NR==1; ($2~/^-$/)' | head -n1 | tr '\t' '\n' | sed 's+ ++g' | grep -xnE $ColumnNamesSubset | sed 's+:+\t+g' | cut -f1 | paste -sd,)
		  #extract lane information for the specific columns of interest. Do note that Cluster PF, Aligned and Error has Stand D (+/-). For each of plotting portability in R shiny
		  #these column will be split based on the (+/-). The new column will be have an assigned sd for the main subject.
		  #New column will now be <Lane,Cluster PF,Cluster PF sd,Reads,Reads PF.%>=Q30,Yield,Aligned,Aligned sd,Error,Error sd 
		  LaneMetrics=$(cat $RunMetricsSummary | grep -A$(sed -n '/Cluster PF/,$p' $RunMetricsSummary | wc -l) "Cluster PF" | sed -n '/Read 2 (I)/q;p' \
		  | tr ',' '\t' | awk 'NR==1; ($2~/^-$/)' | cut -f $LaneMetColNum | tr '+/-' '\t' | sed '1d; s+nan+NULL+g; s/\t\+/\t/g;s/^\t//; s/ *\t */\t/g; s/[[:blank:]]*$//')
		  LaneTotal=$(echo "$LaneMetrics" | wc -l)
		  for Lanes in $(seq 1 $LaneTotal); do
			  Lane=$(echo $(echo "$LaneMetrics" | head -n $Lanes | tail -n1 | cut -f1))
			  Cluster_PF=$(echo $(echo "$LaneMetrics" | head -n $Lanes | tail -n1 | cut -f2))
			  Cluster_PF_SD=$(echo $(echo "$LaneMetrics" | head -n $Lanes | tail -n1 | cut -f3))
			  Reads=$(echo $(echo "$LaneMetrics" | head -n $Lanes | tail -n1 | cut -f4))
			  Reads_PF=$(echo $(echo "$LaneMetrics" | head -n $Lanes | tail -n1 | cut -f5))
			  Percent_Q30=$(echo $(echo "$LaneMetrics" | head -n $Lanes | tail -n1 | cut -f6))
			  Yield=$(echo $(echo "$LaneMetrics" | head -n $Lanes | tail -n1 | cut -f7))
			  Aligned=$(echo $(echo "$LaneMetrics" | head -n $Lanes | tail -n1 | cut -f8))
			  Aligned_SD=$(echo $(echo "$LaneMetrics" | head -n $Lanes | tail -n1 | cut -f9))
			  Error=$(echo $(echo "$LaneMetrics" | head -n $Lanes | tail -n1 | cut -f10))
			  Error_SD=$(echo $(echo "$LaneMetrics" | head -n $Lanes | tail -n1 | cut -f11))
			  gather_metrics_js >> $OUT/"$projectId"_QCreport.$Application.$n.txt
		  done
	  else
		  InstrumentID=NULL
		  FlowCellID=NULL
		  RunID=NULL
		  Lane=NULL
		  Cluster_PF=NULL
		  Cluster_PF_SD=NULL
		  Reads=NULL
		  Reads_PF=NULL
		  Percent_Q30=NULL
		  Yield=NULL
		  Aligned=NULL
		  Aligned_SD=NULL
		  Error=NULL
		  Error_SD=NULL
		  ####
		  gather_metrics_js > $OUT/"$projectId"_QCreport.$Application.$n.txt
	  fi
	  #If database is present and not empty, update sample metric, one at a time
	  Sample=$(cat $OUT/"$projectId"_QCreport.$Application.$n.txt | cut -f6 | sort | uniq)
	  if [[ -s "$OUT/$Application.metrics.txt" ]]; then 
		  printf '%s\n' $Sample | while read SAMPLE ; do
		    #Sample_check=$(grep "$SAMPLE" $OUT/$Application.metrics.txt | cut -f6 | sort | uniq)
        # awk -F'\t' '!(($1=="NULL") && ($3=="NULL"))'
		    grep "$SAMPLE" $OUT/"$projectId"_QCreport.$Application.$n.txt | sed -r 's/\s+\S+$//' > $OUT/Sample_met_1.$Application.$projectId.$projectFinal #removes samples likely from troubleshooting folder. relies on empty columns 1 and 3 which was assigned NULL
		    grep "$SAMPLE" $OUT/$Application.metrics.txt | sed -r 's/\s+\S+$//' > $OUT/Sample_met_2.$Application.$projectId.$projectFinal
		    #sort $OUT/Sample_met_1.$Application.$projectId.$projectFinal $OUT/Sample_met_2.$Application.$projectId.$projectFinal | uniq -u > $OUT/Sample_met_1-2.$Application.$projectId.$projectFinal
		    sort $OUT/Sample_met_1.$Application.$projectId.$projectFinal $OUT/Sample_met_2.$Application.$projectId.$projectFinal | uniq -u | sed -e 's/$/\tNULL/' >> $OUT/$Application.metrics.txt
        #If metrics are duplicated where one qifa-qc release command is issued for one but not the other, it may indicate analyst created duplicate ...
        #for troubleshooting purpose. We should remove that line
		    #if [[ "$(grep "$SAMPLE" $OUT/$Application.metrics.txt | wc -l)" -ge 2 ]] ; then 
			  #  awk -F'\t' -v rm_dup_met=`echo $SAMPLE` '!(rm_dup_met && ((($1 ~ /NULL/) && ($3 ~ /NULL/)) || ($4 ~ /NULL/)))' $OUT/$Application.metrics.txt > $OUT/.tmp.$Application
			  #  mv $OUT/.tmp.$Application $OUT/$Application.metrics.txt
		    #fi
        rm $OUT/Sample_met_1.$Application.$projectId.$projectFinal
        rm $OUT/Sample_met_2.$Application.$projectId.$projectFinal
          #rm $OUT/Sample_met_1-2.$Application.$projectId.$projectFinal
		  done
	  else #Create new database if non exist
		  #awk 'FNR != 1'
		  cat $OUT/"$projectId"_QCreport.$Application.$n.txt >> $OUT/$Application.metrics.txt
      #printf '%s\n' $Sample | while read SAMPLE ; do
      #  if [[ "$(grep "$SAMPLE" $OUT/$Application.metrics.txt | wc -l)" -ge 2 ]] ; then 
			#    awk -F'\t' -v rm_dup_met=`echo $SAMPLE` '!(rm_dup_met && ((($1 ~ /NULL/) && ($3 ~ /NULL/)) || ($4 ~ /NULL/)))' $OUT/$Application.metrics.txt > $OUT/.tmp.$Application
			#    mv $OUT/.tmp.$Application $OUT/$Application.metrics.txt
      #  fi
		  #done
	  fi
	  rm $OUT/"$projectId"_QCreport.$Application.csv 
	  rm $OUT/"$projectId"_QCreport.$Application.$n.txt
	  rm $OUT/"$projectId"_QCreport.$Application.log
  done
  #Also remove lines where no data is populated for read total. This usually happen if certain file is absent.     
  if [[ -f "$OUT/.$Application.activate_pulling_NULL_metrics_archive.txt" ]]; then
    rm $OUT/.$Application.activate_pulling_NULL_metrics_archive.txt
  fi
}
#
#

function minor_fixes {
#reformart species id
SpeciesColNum=$(head -n1 $OUT/$Application.metrics.txt | tr '\t' '\n' | nl | grep "Species" | cut -f1)
cat $OUT/$Application.metrics.txt | awk -F '\t' -v ColNum="$SpeciesColNum" '{gsub("homo sapiens","Homo sapiens",$ColNum); print}' OFS="\t" | \
 awk -F '\t' -v ColNum="$SpeciesColNum" '{gsub("Human","Homo sapiens",$ColNum); print}' OFS="\t" | \
 awk -F '\t' -v ColNum="$SpeciesColNum" '{gsub("human","Homo sapiens",$ColNum); print}' OFS="\t" > $OUT/.tmp.$Application
#metrics with "other" species usually have unequal rows. Calculate the column and update the field with NULL. Then update other minor fixes
col_total=$(head -n1 $OUT/.tmp.$Application | tr '\t' '\n' | wc -l)
cat $OUT/.tmp.$Application | awk -F'\t' -v OFS='\t' -v N="$col_total" '{while(colNr++<N){$colNr=($colNr==""?"NULL":$colNr)}colNr=0}1' | \
sed 's+"++g; s/n\.a\./NULL/g; s+NaN+NULL+g' > $OUT/.tmp2.$Application
mv $OUT/.tmp2.$Application $OUT/$Application.metrics.txt
#reformat the GT_QC_Sample_ID column. Gatekeeper does not want prefix attached to GT e.g. 1_GT
awk -F'\t' 'BEGIN {OFS = FS} {sub(/.*GT/,"GT",$5); print}' $OUT/$Application.metrics.txt > $OUT/.tmp.$Application
mv $OUT/.tmp.$Application $OUT/$Application.metrics.txt

#extract last column with unassinged project status and then pass that to project status function to speed up compute
awk '/NULL$/' $OUT/$Application.metrics.txt > $OUT/.tmp1.$Application
awk '!/NULL$/' $OUT/$Application.metrics.txt > $OUT/.tmp2.$Application
mv $OUT/.tmp2.$Application $OUT/$Application.metrics.txt
}
###
###
###
#Assign Project Status. If QC was delivered, assigne Delivered, else Undelivered. 
#Logic is undelivered QC will not have PI delivery folder stamp (or possibly release date) in .settings
#It is important for the content of the archival to be accurate.
#if [[ -z "$(tail -n +2 $OUT/$Application.metrics.txt)" ]]; then
#	echo -e "No metrics available to gather for  '$Application'"
#	exit 1;
function proj_status {
	while IFS="" read -r p || [ -n "$p" ]
	do
		if [[ "$(printf '%s\n' "$p" | awk -F'\t' '($1 == "NULL") || ($4 == "NULL")')" ]] ; then
			printf '%s\n' "$p" | sed 's/\S*$/Undelivered/' >> $OUT/.tmp.$Application
 		else
  			printf '%s\n' "$p" | sed 's/\S*$/Delivered/' >> $OUT/.tmp.$Application
 		fi
	done < $OUT/.tmp1.$Application
  	#mv $OUT/.tmp.$Application $OUT/$Application.metrics.txt
  	cat $OUT/.tmp.$Application >> $OUT/$Application.metrics.txt
  	rm $OUT/.tmp1.$Application
}
###
###
###
#Assign header to database, if absent
function update_header {
header=$(head -n1 $qifaPipelineDir/qifa-qc-scripts/$Application/$Application.pe.report.database.template | column -t -s, | sed "s/{.*//; 
  1s/^/Lane\t/; 1s/^/FlowcellID\t/; 1s/^/InstrumentID\t/;
	1s/^/RunID\t/; 1s/^/Release_Date\t/; 1s/^/Project_run_type\t/; 1s/^/Project_ID\t/; 
  1s/^/Investigator_Folder\t/; 1s/$/\tCluster_PF_PCT/; 
  1s/$/\tCluster_PF_SD_PCT/; 1s/$/\tReads_Cluster_number_Mb/; 1s/$/\tReads_Cluster_number_PF_Mb/; 
	1s/$/\tQ30_or_higher_PCT/; 1s/$/\tYield_Gb/; 1s/$/\tAligned_PhiX_PCT/; 1s/$/\tAligned_PhiX_SD_PCT/;
	1s/$/\tError_rate_PhiX_alignment/ ; 1s/$/\tError_rate_PhiX_alignment_SD/ ; 1s/$/\tProjStatus/")
if [[ -f "$OUT/$Application.metrics.txt" && ! "$(grep "Sample_Name" $OUT/$Application.metrics.txt)" ]]; then
#header_check=$(grep "Sample_Name" $OUT/$Application.metrics.txt) #Logic relies on the presence of "Sample_Name". Additional constant string may be used in future
	echo $header | tr ' ' '\t' | cat - $OUT/$Application.metrics.txt > $OUT/.tmp.$Application && mv $OUT/.tmp.$Application $OUT/$Application.metrics.txt
else
	cat $OUT/$Application.metrics.txt | tail -n+2 > $OUT/.tmp.$Application
  mv $OUT/.tmp.$Application $OUT/$Application.metrics.txt
	echo $header | tr ' ' '\t' | cat - $OUT/$Application.metrics.txt > $OUT/.tmp.$Application
  mv $OUT/.tmp.$Application $OUT/$Application.metrics.txt
fi
if [[ ! -f "$OUT/$Application.metrics.txt" ]] ; then 
	echo -e 'ERROR: Cannot add header to  '$Application' metrics database. '$OUT/$Application.metrics.txt' is missing' | mail -s "Failed adding header to metrics database" $Email
	exit 1;
fi
}
###
###
#remove duplicates metrics and lines where no metrics is recorded
function dup_rm {
  ColNum1=$(head -n1 $OUT/$Application.metrics.txt | tr '\t' '\n' | nl | grep "Reads_Total" | cut -f1)
  if [[ "$(cat $OUT/$Application.metrics.txt | awk -F'\t' -v Col=`echo $ColNum1` '$Col == "NULL"')" ]] ; then
    awk -F'\t' -v ColNum_1="$ColNum1" '!($ColNum_1 ~ /NULL/)' $OUT/$Application.metrics.txt > $OUT/.tmp.$Application 
    mv $OUT/.tmp.$Application $OUT/$Application.metrics.txt
  fi 
  awk '!seen[$0]++' $OUT/$Application.metrics.txt > $OUT/.tmp.$Application
  mv $OUT/.tmp.$Application $OUT/$Application.metrics.txt;
}
###
###
function push_update_to_ctgenometech03_server {
	rsync -vahP $OUT/$Application.metrics.txt ctgenometech03:/srv/shiny-server/.InputDatabase
}
###
###
function bailout_noupdate {
if [[ -f "$OUT/.GTmetricsbackup/.$Application.metrics.$day_present.txt" ]]; then
	if [[ "$(diff $OUT/$Application.metrics.txt $OUT/.GTmetricsbackup/.$Application.metrics.$day_present.txt)" ]]; then
		minor_fixes
  		proj_status
  		update_header
  		dup_rm
		push_update_to_ctgenometech03_server
	fi
fi
}
###
###
catch_email_failure() {
   exit_code=$?
   if [[ ${exit_code} -ne 0 ]]; then
      ErrMsg1=$(cat $OUT/.logfile)
      echo -e "Failure to GT metrics database update encountered. No new update will be pushed to web interface. \n\nReview error file @ $OUT or faulty command line below:
      \n $ErrMsg1" | mail -s "Failure: GT metrics database update" $Email
      > $OUT/.logfile
      cp $OUT/.GTmetricsbackup/.$Application.metrics.$day_present.txt $OUT/$Application.metrics.txt 
   fi
}

trap 'failed_command $LINENO ${BASH_LINENO[@]}' ERR
trap 'catch_email_failure' EXIT 
#
#
init_command 2>/dev/null
#
#if [[ -s "$OUT/.errorfile2" ]]; then
#  ErrMsg2=$(cat $OUT/.errorfile2)
#  echo -e "Error identified while updating metrics table for interface. \nNo new update will be pushed to web interface. \n\n Reveiw message:\n\n $ErrMsg2" | mail -s "Failed adding header to metrics database" $Email
#  cp $OUT/.GTmetricsbackup/.$Application.metrics.$day_present.txt $OUT/$Application.metrics.txt 
#fi
