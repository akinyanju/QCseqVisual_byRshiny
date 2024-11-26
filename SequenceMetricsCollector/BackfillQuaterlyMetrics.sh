#!/usr/bin/env bash

#SBATCH -p gt_compute
#SBATCH --cpus-per-task=1
#SBATCH -t 1:00:00
#SBATCH --mem=4G
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=raman.lawal@jax.org
#SBATCH --job-name=backFillQuaterlyMetrics
##SBATCH --output=/gt/research_development/lawalr/TestFolder/quaterlyMetrics/updateTable/%x.%N.o%j.log

qcdir=/gt/data/seqdma/.qifa.qc-archive
export SETJSONFILE=".settings.json"
export RunInfo="RunInfo.xml"
OUT="/gt/research_development/lawalr/TestFolder/quaterlyMetrics/updateTable"
MetricFile="SequencingMetrics"

########################################################
#backup file to update
#cp $OUT/$MetricFile.csv $OUT/$MetricFile.backup.csv

function fill_coln {
    releaseMon=$(expr $releaseMonth + 0)
    rowNo=$(cat $OUT/$MetricFile.csv | awk -F, -v D="$DeliveryDirectory" -v P="$Project" \
        -v Pl="$Platform" -v Y="$releaseYear" -v M="$releaseMon" \
        '$1 == M && $2 == Y && $3 == P && $10 == Pl && $14 == D {print NR}')

	if [[ -z "$rowNo" ]] ; then
		rowNo=$(cat $OUT/$MetricFile.csv | awk -F, -v P="$Project" \
        -v Pl="$Platform" -v Y="$releaseYear" -v M="$releaseMon" \
        '$1 == M && $2 == Y && $3 == P && $10 == Pl {print NR}')
	fi

 #   rowNo=$(cat $OUT/$MetricFile.csv | grep -n "$DeliveryDirectory" | grep $Project | grep $Application \
  #      | grep $Platform | awk -F, -v Year="$releaseYear" '$2 == Year' | sed 's+:+\t+g' | cut -f1)

    if [[ -z "$SampleSize" ]] ; then
        SampleSize=0
    fi
    if [[ -z "$PolymeraseRLbp" ]] ; then
        PolymeraseRLbp=0
    fi
    #If information is accurate in a row, forget updating that row and go to next
    SampleCheck=$(awk -F, -v row_num="$rowNo" 'NR == row_num { print $0}' $OUT/$MetricFile.csv | cut -d, -f15)
    MachineCheck=$(awk -F, -v row_num="$rowNo" 'NR == row_num { print $0}' $OUT/$MetricFile.csv | cut -d, -f5)
    if [[ "$(echo $SampleCheck)" != "$(echo $SampleSize)" || "$(echo $MachineCheck)" != "$(echo $InstrumentID)" ]] ; then 
        if [[ "$(printf '%s\n' $rowNo | wc -l)" == "1" && ! -z "$rowNo" ]] ; then
            if [[ "$(echo $PolymeraseRLbp)" != "0" ]] ; then
                #include row to update
                cat $OUT/$MetricFile.csv | awk -F, -v row_num="$rowNo" 'NR == row_num { print $0}' > $OUT/rowToUpdate.csv
                cat $OUT/$MetricFile.csv | awk -F, -v row_num="$rowNo" 'NR == row_num { print $0}' >> $OUT/All.rowToUpdate.csv
                #exclude row to update
                cat $OUT/$MetricFile.csv | awk -F, -v row_num="$rowNo" 'NR != row_num { print $0}' > $OUT/$MetricFile.tmp.csv 
                mv $OUT/$MetricFile.tmp.csv $OUT/$MetricFile.csv
                #MetricsLessRowToUpdate=$(cat $OUT/$MetricFile.csv | awk -F, -v row_num="$rowNo" 'NR != row_num { print $0}')
                cat $OUT/rowToUpdate.csv | awk -F, -v search_1="NULL" -v search_2="0" -v col_num5=5 -v col_num15=15 -v col_num16=16 \
                    -v Machine="$InstrumentID" -v Samplen="$SampleSize" -v Polymerase="$PolymeraseRLbp" \
                    'BEGIN{FS=OFS=","} {
                    if ($col_num5 ~ search_1) {$col_num5 = Machine}
                    if ($col_num15 ~ search_2) {$col_num15 = Samplen}
                    if ($col_num16 ~ search_2) {$col_num16 = Polymerase}
                    }'1 >> $OUT/$MetricFile.updatedrow.csv
            else
                cat $OUT/$MetricFile.csv | awk -F, -v row_num="$rowNo" 'NR == row_num { print $0}' > $OUT/rowToUpdate.csv
                cat $OUT/$MetricFile.csv | awk -F, -v row_num="$rowNo" 'NR == row_num { print $0}' >> $OUT/All.rowToUpdate.csv
                #exclude row to update
                cat $OUT/$MetricFile.csv | awk -F, -v row_num="$rowNo" 'NR != row_num { print $0}' > $OUT/$MetricFile.tmp.csv 
                mv $OUT/$MetricFile.tmp.csv $OUT/$MetricFile.csv
                #MetricsLessRowToUpdate=$(cat $OUT/$MetricFile.csv | awk -F, -v row_num="$rowNo" 'NR != row_num { print $0}')
                cat $OUT/rowToUpdate.csv | awk -F, -v search_1="NULL" -v search_2="0" -v col_num5=5 -v col_num15=15 -v col_num16=16 \
                    -v Machine="$InstrumentID" -v Samplen="$SampleSize" -v Polymerase="$PolymeraseRLbp" \
                    'BEGIN{FS=OFS=","} {
                    if ($col_num5 ~ search_1) {$col_num5 = Machine}
                    if ($col_num15 ~ search_2) {$col_num15 = Samplen}
                    }'1 >> $OUT/$MetricFile.updatedrow.csv
            fi 
         else 
            printf '%s\n' $rowNo | while read LineNo ; do
                cat $OUT/$MetricFile.csv | awk -F, -v row_num="$LineNo" 'NR == row_num { print $0}' > $OUT/rowToUpdate.csv
                cat $OUT/$MetricFile.csv | awk -F, -v row_num="$rowNo" 'NR == row_num { print $0}' >> $OUT/All.rowToUpdate.csv
                #exclude row to update
                cat $OUT/$MetricFile.csv | awk -F, -v row_num="$LineNo" 'NR != row_num { print $0}' > $OUT/$MetricFile.tmp.csv 
                mv $OUT/$MetricFile.tmp.csv $OUT/$MetricFile.csv
                #MetricsLessRowToUpdate=$(cat $OUT/$MetricFile.csv | awk -F, -v row_num="$rowNo" 'NR != row_num { print $0}')
                cat $OUT/rowToUpdate.csv | awk -F, -v search_1="NULL" -v Machine="$InstrumentID" \
                    'BEGIN{FS=OFS=","} {
                    if ($col_num5 ~ search_1) {$col_num5 = Machine}
                    }'1 >> $OUT/$MetricFile.updatedrow.csv
            done
        fi
    fi
}
function collect_qcdir {
	if [[ ! -f "$OUT/.SequencingMetricsQCdir.txt" ]]; then
		find  $qcdir -mindepth 4 -maxdepth 4 -type d >> $OUT/.SequencingMetricsQCdir.txt
		awk '!seen[$0]++' $OUT/.SequencingMetricsQCdir.txt > $OUT/.tmp.SequencingMetricsQCdir.txt
		mv $OUT/.tmp.SequencingMetricsQCdir.txt $OUT/.SequencingMetricsQCdir.txt
		ProjDirs=`cat $OUT/.SequencingMetricsQCdir.txt`
		ProjTotal=`echo -en "$ProjDirs\n" | wc -l`
	else
		cat $OUT/.SequencingMetricsQCdir.txt | awk '!seen[$0]++' >> $OUT/.SequencingMetricsQCdir.update.txt
        awk '!seen[$0]++' $OUT/.SequencingMetricsQCdir.update.txt > $OUT/.tmp.SequencingMetricsQCdir.update.txt
        mv $OUT/.tmp.SequencingMetricsQCdir.update.txt $OUT/.SequencingMetricsQCdir.update.txt
        find  $qcdir -mindepth 4 -maxdepth 4 -type d >> $OUT/.SequencingMetricsQCdir.txt
        #extract only the new QC folder
        grep -vf $OUT/.SequencingMetricsQCdir.update.txt $OUT/.SequencingMetricsQCdir.txt > $OUT/.tmp.SequencingMetricsQCdir.txt
        mv $OUT/.tmp.SequencingMetricsQCdir.txt $OUT/.SequencingMetricsQCdir.txt
        DirList=`cat $OUT/.SequencingMetricsQCdir.txt`
	    ProjDirs=`cat $OUT/.SequencingMetricsQCdir.txt`
	    ProjTotal=`echo -en "$ProjDirs\n" | wc -l`
	fi
}

function collect_metrics {
	for n in $(seq 1 $ProjTotal); do
	ProjDir=`echo -en "$ProjDirs\n" | head -n $n | tail -n1`
		if [[ -f "$ProjDir/$SETJSONFILE" ]]; then
			if [[ "$(grep -w packageTimestamp $ProjDir/$SETJSONFILE 2> /dev/null)" ]] ; then
				releaseMonth=$(grep -w packageTimestamp $ProjDir/$SETJSONFILE | awk '{print $2}' | grep -o '".*"' | sed 's/"//g' | cut -d"-" -f2)
				releaseYear=$(grep -w packageTimestamp $ProjDir/$SETJSONFILE | awk '{print $2}' | grep -o '".*"' | sed 's/"//g' | cut -d"-" -f1)
				Project=$(grep -w project $ProjDir/$SETJSONFILE | awk '{print $2}' | grep -o '".*"' | sed 's/"//g')
				groupFolder=$(grep deliveryFolder $ProjDir/$SETJSONFILE | awk '{print $2}' | grep -o '".*"' | sed 's/"//g' | awk -F/ '{print $4}')
				RunFolderDir="${ProjDir%/*}"
				RunFolder=${RunFolderDir##*/}
				Application=$(grep '"application":' $ProjDir/$SETJSONFILE | awk '{print $2}' | grep -o '".*"' | sed 's/"//g')
				releasePath=$(grep releasePath $ProjDir/$SETJSONFILE | awk '{print $2}' | grep -oP '(?<=").*(?=")' | sed -e 's+^+/gt+g')
				DeliveryDirectory=$(echo "${releasePath##*/}")
				projectFinal=$(grep projectFinal $ProjDir/$SETJSONFILE | awk '{print $2}' | grep -o '".*"' | sed 's/"//g')
			else
				releaseMonth=$(expr $(echo "${ProjDir%/*/*}" | sed 's:.*/::; s+-+\t+'  | cut -f2) + 0)
				releaseYear=$(echo "${ProjDir%/*/*}" | sed 's:.*/::; s+-+\t+'  | cut -f1)
				Project=$(grep -w project $ProjDir/$SETJSONFILE | awk '{print $2}' | grep -o '".*"' | sed 's/"//g')
				RunFolderDir="${ProjDir%/*}"
				RunFolder=${RunFolderDir##*/}
				Application=$(grep '"application":' $ProjDir/$SETJSONFILE | awk '{print $2}' | grep -o '".*"' | sed 's/"//g')
			fi
		fi
        #Set Platform
        if [[ "$Application" != "ONT" && "$Application" != "PacBio" && "$$Application" != "PACBIO" ]]; then
            Platform=Illumina
        elif [[ "$Application" == "ONT" ]] ; then
            Platform=ONT
        elif [[ "$Application" == "PacBio" ]] ; then
            Platform=PacBio
        elif [[ "$$Application" == "PACBIO" ]] ; then
            Platform=PacBio
        fi

        #collect the instrument ID
         if [[ "$Platform" == "Illumina" ]]; then
		    if [[ "$(ls $ProjDir 2> /dev/null | grep "Run_Metric_Summary" | grep "draft")" ]] ; then
			    export RunMetricsSummary=$ProjDir/$(ls $ProjDir | grep "Run_Metric_Summary" | grep "draft")
			    InstrumentName=$(grep -A1 "FlowCellID" $RunMetricsSummary | tr ',' '\t' | sed 's+"++g' | \
		  		    awk 'NR == 1{ for(i=1; i<=NF; i++) if ($i == "MachineID") { pos = i; break } } NR == 2{ print $pos; exit }')
		    elif [[ "$(ls $ProjDir 2> /dev/null | grep "Run_Metric_Summary.csv")" ]] ; then
			    export RunMetricsSummary=$ProjDir/$(ls $ProjDir | grep "Run_Metric_Summary.csv")
			    InstrumentName=$(grep -A1 "FlowCellID" $RunMetricsSummary | tr ',' '\t' | sed 's+"++g' | \
		  		    awk 'NR == 1{ for(i=1; i<=NF; i++) if ($i == "MachineID") { pos = i; break } } NR == 2{ print $pos; exit }')
		    elif [[ "$(ls $ProjDir/package 2> /dev/null | grep "Run_Metric_Summary" | grep "draft")" ]] ; then
			    export RunMetricsSummary=$ProjDir/package/$(ls $ProjDir/package | grep "Run_Metric_Summary" | grep "draft")
			    InstrumentName=$(grep -A1 "FlowCellID" $RunMetricsSummary | tr ',' '\t' | sed 's+"++g' | \
		  		    awk 'NR == 1{ for(i=1; i<=NF; i++) if ($i == "MachineID") { pos = i; break } } NR == 2{ print $pos; exit }')
		    elif [[ "$(ls $ProjDir/package 2> /dev/null | grep "Run_Metric_Summary.csv")" ]] ; then
			    export RunMetricsSummary=$ProjDir/package/$(ls $ProjDir | grep "Run_Metric_Summary.csv")
			    InstrumentName=$(grep -A1 "FlowCellID" $$RunMetricsSummary | tr ',' '\t' | sed 's+"++g' | \
		  		    awk 'NR == 1{ for(i=1; i<=NF; i++) if ($i == "MachineID") { pos = i; break } } NR == 2{ print $pos; exit }')
		    elif [[ "$(ls $ProjDir 2> /dev/null | grep "$RunInfo")" ]]; then
			    InstrumentName=$(grep "Instrument" $ProjDir/$RunInfo | sed -r 's/\s+//g' | tr '>' '\t' | tr '<' '\t' | sed -r 's/^\s+//g' | cut -f2)
		    else
			    InstrumentName=$RunFolder
		    fi
			if [[ "$(echo $InstrumentName | grep "M02838" 2> /dev/null)" ]] ; then
            	InstrumentID="CT_MiSeq_M02838"
			elif [[ "$(echo $InstrumentName | grep "M03204" 2> /dev/null)" ]]; then
				InstrumentID="CT_MiSeq_M03204"
			elif [[ "$(echo $InstrumentName | grep "VH01929" 2> /dev/null)" ]]; then
				InstrumentID="CT_NextSeq2000_VH01929"
			elif [[ "$(echo $InstrumentName | grep "A00724" 2> /dev/null)" ]]; then
				InstrumentID="CT_NovaSeq6000_A00724"
			elif [[ "$(echo $InstrumentName | grep "A00739" 2> /dev/null)" ]]; then
				InstrumentID="CT_NovaSeq6000_A00739"
			elif [[ "$(echo $InstrumentName | grep "LH00341" 2> /dev/null)" ]]; then
				InstrumentID="CT_NovaSeqX_Plus_LH00341"
			elif [[ "$(echo $InstrumentName | grep "M00263" 2> /dev/null)" ]] ; then
				InstrumentID="BH_MiSeq_M00263"
			elif [[ "$(echo $InstrumentName | grep "VH01930" 2> /dev/null)" ]] ; then
				InstrumentID="BH_NextSeq2000_VH01930"
			elif [[ "$(echo $InstrumentName | grep "NB501381" 2> /dev/null)" ]] ; then
				InstrumentID="BH_NextSeq500_NB501381"
			elif [[ "$(echo $InstrumentName | grep "D00138" 2> /dev/null)" ]] ; then
				InstrumentID="CT_HiSeq2500_D00138"
			elif [[ "$(echo $InstrumentName | grep "K00384" 2> /dev/null)" ]] ; then
				InstrumentID="CT_Illumina_HiSeq4000_K00384"               
			elif [[ "$(echo $InstrumentName | grep "M03341" 2> /dev/null)" ]] ; then
				InstrumentID="CT_MiSeq_M03341"               
			elif [[ "$(echo $InstrumentName | grep "NB501370" 2> /dev/null)" ]] ; then
				InstrumentID="CT_NextSeq500_NB501370"               
			elif [[ "$(echo $InstrumentName | grep "NS500440" 2> /dev/null)" ]] ; then
				InstrumentID="CT_NextSeq500_NS500440"               
			elif [[ "$(echo $InstrumentName | grep "NS500460" 2> /dev/null)" ]] ; then
				InstrumentID="CT_NextSeq500_NS500460"               
			elif [[ "$(echo $InstrumentName | grep "NS500440" 2> /dev/null)" ]] ; then
				InstrumentID="CT_NextSeq500_NS500440"               
			elif [[ "$(echo $InstrumentName | grep "245735200492" 2> /dev/null)" ]] ; then
				InstrumentID="CT_ThermoFisher_IonTorrentS5XL_245735200492"   
			elif [[ "$(echo $InstrumentName | grep "IonTorrent" 2> /dev/null)" ]] ; then
				InstrumentID="CT_ThermoFisher_IonTorrentS5XL_245735200492"             
			else
				InstrumentID=NULL
        	fi
		    ###Calculate the total reads, bases and folder size
			if [[ -d "$ProjDir/basic" ]] ; then
				ls $ProjDir/basic/*.json > $OUT/.$Platform.$DeliveryDirectory.txt 
		    	Reads=`printf '%s\n' \
			    	$(paste $OUT/.$Platform.$DeliveryDirectory.txt  | while read SAMPLE ; do
				    	grep -A2 '"before_filtering":' "$SAMPLE" | grep '"total_reads":' | awk -F':' '{print $2}' | sed 's+,++g'
			    	done) | paste -sd+ - | bc` #numfmt --grouping
		    	Bases=`printf '%s\n' \
			    	$(paste $OUT/.$Platform.$DeliveryDirectory.txt  | while read SAMPLE ; do
				    	grep -A2 '"before_filtering":' "$SAMPLE" | grep '"total_bases":' | awk -F':' '{print $2}' | sed 's+,++g'
			    	done) | paste -sd+ - | bc`
		    	SampleSize=$(ls $ProjDir/basic/*.json | grep -v "Undetermined"  | wc -l)
				PolymeraseRLbp="0"
		    	rm $OUT/.$Platform.$DeliveryDirectory.txt 
			fi
        elif [[ "$Platform" == "ONT" ]]; then
            if [[ -f "$ProjDir/.qifa.ont.json" ]] ; then
                if [[ "$(grep '"hostname":' $ProjDir/.qifa.ont.json  | awk '{print $2}' | grep -o '".*"' | sed 's/"//g')" ]] ; then
                    InstrumentName=$(grep '"hostname":' $ProjDir/.qifa.ont.json  | awk '{print $2}' | grep -o '".*"' | sed 's/"//g')
                elif [[ "$(grep '"host_product_serial_number":' $ProjDir/.qifa.ont.json  | awk '{print $2}' | grep -o '".*"' | sed 's/"//g')" ]] ; then
                    InstrumentName=$(grep '"hostname":' $ProjDir/.qifa.ont.json  | awk '{print $2}' | grep -o '".*"' | sed 's/"//g')
                fi
            else 
                InstrumentName="NULL"
            fi
			if [[ "$(echo $InstrumentName | grep "GXB02036" 2> /dev/null)" ]] ; then
            	InstrumentID="CT_GridIONX5_GXB02036"
			elif [[ "$(echo $InstrumentName | grep "PCA100115" 2> /dev/null)" ]] ; then
				InstrumentID="CT_PromethION_PCA100115"
			elif [[ "$(echo $InstrumentName | grep "GXB03074" 2> /dev/null)" ]] ; then
				InstrumentID="BH_GridIONX5_GXB03074"
			elif [[ "$(echo $InstrumentName | grep "P2S-01535" 2> /dev/null)" ]] ; then
				InstrumentID="BH_P2_Solo_P2S-01535"
			elif [[ "$(echo $InstrumentName | grep "GXB01025" 2> /dev/null)" ]] ; then
				InstrumentID="CT_GridIONX5_GXB01025"
			elif [[ "$(echo $InstrumentName | grep "GXB01102" 2> /dev/null)" ]] ; then
				InstrumentID="CT_GridIONX5_GXB01102"
			elif [[ "$(echo $InstrumentName | grep "GXB01186" 2> /dev/null)" ]] ; then
				InstrumentID="CT_GridIONX5_GXB01186"
			elif [[ "$(echo $InstrumentName | grep "PC24B149" 2> /dev/null)" ]] ; then
				InstrumentID="CT_PromethION_PC24B149"
			elif [[ "$(echo $InstrumentName | grep "PCT0053" 2> /dev/null)" ]] ; then
				InstrumentID="CT_PromethION_PCT0053"
			else
				InstrumentID=$InstrumentName
        	fi
            ###collect metrics from ${projectFinal}_QCreport.csv, else, calculate that from the fastq
            if [[ "$(ls $ProjDir/package/*csv 2> /dev/null)" ]] ; then
                QCreport=$(ls $ProjDir/package/*csv | grep QCreport)
                SampleSize=$(cat $QCreport | grep "Sample Size:" | tr ':' '\t' | cut -f2)
            else
                SampleSize=0
            fi
            PolymeraseRLbp="0"
		elif [[ "$Platform" == "PacBio" ]]; then
			#Position of the delivery directory is different thatn with the ont
			DeliveryDirectory=$(echo "${releasePath#*`echo $groupFolder/`}" | sed 's+/+\t+g' | cut -f1)
			#xmlfile=$(grep "DestPath" $ProjDir/m64119_220619_012431.subreadset.xml)
            #InstrumentRunPath=${xmlfile%/*} 
            #echo ${InstrumentRunPath##*/}  | sed 's+<++g; s+_+\t+g' | awk '{print $NF}'
            InstrumentName=$(echo $RunFolder | sed 's|_[^/]*$||')
			if [[ -z "$InstrumentName" ]] ; then
				if [[ -f "$ProjDir/CCS_Report_${projectFinal}*.html" ]] ; then
         			InstrumentName=$(grep "Instrument Name" $ProjDir/CCS_Report_${projectFinal}*.html | \
            		sed 's+<tr><th>++g; s+</th><td>+\t+g; s+</td></tr>++g; s+Instrument Name++g') 
    			fi
			fi
			if echo $InstrumentName | grep "84148" >/dev/null 2>&1; then
            	InstrumentID="CT_Revio_84148"
			elif echo $InstrumentName | grep "SQ65119" >/dev/null 2>&1 ; then
            	InstrumentID="CT_Sequel_SQ65119"
            elif echo $InstrumentName | grep "64119" >/dev/null 2>&1 ; then
            	InstrumentID="CT_Sequel_SQ65119"
            elif echo $InstrumentName | grep "SQ65039" >/dev/null 2>&1 ; then
            	InstrumentID="CT_Sequel_SQ65039"
            elif echo $InstrumentName | grep "r64039" >/dev/null 2>&1 ; then
            	InstrumentID="CT_Sequel_SQ65039"
			else
				InstrumentID=$InstrumentName
        	fi
		#
    		if [[ -f "$ProjDir/package/Run_Report_${projectFinal}.csv" ]] ; then
        		Well="${RunFolder##*_}"
        		WellColNum=$(sed -n '/Sample Name/,$p' $ProjDir/package/Run_Report_${projectFinal}.csv |  \
            		head -n1 | tr ',' '\n' | nl | grep "Sample Well" | cut -f1)
				PolymeraseRLbp=`sed -n '/Sample Name/,$p' $ProjDir/package/Run_Report_${projectFinal}.csv |  \
        			awk -F'"' -v OFS='' '{ for (i=2; i<=NF; i+=2) gsub(",", "", $i) } 1' | \
            		tr ',' '\t' | awk -v ColNum="$WellColNum" -v cell="$Well" 'NR==1; $ColNum ~ cell { print }' | \
            		cut -f $(sed -n '/Sample Name/,$p' $ProjDir/package/Run_Report_${projectFinal}.csv | \
            		head -n1 | tr ',' '\n' | nl | awk '$2 == "Polymerase"' | cut -f1) | sed '1d' | paste -sd+ - | bc`
    		fi
    		#$ProjDir/package/${projectFinal}_*_QCreport.csv 
            if [[ "$(ls $ProjDir/package/*csv 2> /dev/null)" ]] ; then
                QCreport=$(ls $ProjDir/package/*csv | grep QCreport)
                SampleSize=$(cat $QCreport | grep "Sample Size:" | tr ':' '\t' | cut -f2)
            else
                SampleSize=0
            fi
		fi   
    fill_coln
    done
}    

########################################################
#Once all metrics are computed, below function will output the final dataset

function updatedTable {
	cat $OUT/$MetricFile.updatedrow.csv | sed 's/[[:space:]]*,[[:space:]]*/,/g; s+,,,,,,,,,,,,,,,+,+g' \
		| awk -F, 'NF>1' > $OUT/$MetricFile.formated.updatedrow.csv
	grep -vf $OUT/All.rowToUpdate.csv $OUT/$MetricFile.backup.csv > $OUT/$MetricFile.backup.subset.csv
	cat $OUT/$MetricFile.backup.subset.csv $OUT/$MetricFile.formated.updatedrow.csv > $OUT/$MetricFile.csv

	if [[ "$(wc -l $OUT/$MetricFile.csv | cut -d" " -f1)" == "$(wc -l $OUT/$MetricFile.backup.csv | cut -d" " -f1)" ]] ;then
		rm $OUT/$MetricFile.updatedrow.csv
		rm $OUT/$MetricFile.formated.updatedrow.csv
		rm $OUT/All.rowToUpdate.csv
		rm $OUT/$MetricFile.backup.subset.csv
		rm $OUT/$MetricFile.backup.csv
		rm $OUT/rowToUpdate.csv
	else
		echo "Double check that total lines in $OUT/$MetricFile.backup.csv is same as total lines in $OUT/$MetricFile.csv"
		echo "The $OUT/$MetricFile.csv is the newly updated file and final line count must match with the original"
	fi 
}
########################################################

collect_qcdir
collect_metrics
updatedTable
