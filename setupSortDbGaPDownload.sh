#!/bin/bash

# start with a dbGaP manifest and get list of sources for each ID 
# write them to folder sources
# each file contains ID sra1 [sra2]
# can add more later
# download sra file(s)
# extract fastqs
# if only one pair, rename 
# else merge two into new one

# the first bit will only work if nodes have internet access
# if not, download files initially then run rest of scripts

manifest=$PROJECTDIR/SSSDNM/SRRIDs/manifest_36856_01-22-2018_s.csv
export DBGAPDOWNLOADFOLDER=$PROJECTDIR/newdownloads
export PIPELINEHOMEFOLDER=$PROJECTDIR/SSSDNM

SOURCESFOLDER=$PIPELINEHOMEFOLDER/sources
FASTQFOLDER=$PIPELINEHOMEFOLDER/fastq
if [ ! -e $SOURCESFOLDER ] ; then mkdir $SOURCESFOLDER; fi
if [ ! -e $SOURCESFOLDER/sourceFilesWritten.txt ]
then
	first=yes
	rm -f $SOURCESFOLDER/*.sources.txt
	cat $manifest | while read sra yesno srr srs id rest
	do
		if [ $first = yes ]
		then
			first=no # skip first line of manifest
		else
			if [ -e $PROJECTDIR/SSSDNM/bam/${id}_sorted_unique.bam ]
			then
				continue
			fi
			if [ -e $PROJECTDIR/SSSDNM/fastq/$id.r2.fastq.gz ]
			then
				continue
			fi
			sra=${sra##*/}
			sra=${sra%.sra}
			if [ ! -e $SOURCESFOLDER/$id.sources.txt ]
			then
				echo $id $sra > $SOURCESFOLDER/$id.sources.txt
			else
				cat $SOURCESFOLDER/$id.sources.txt | ( read line; echo $line $sra > tempSources.txt )
				cat tempSources.txt > $SOURCESFOLDER/$id.sources.txt
			fi
		fi	
	done
	rm -f tempSources.txt
	echo Got sources from $manifest > $SOURCESFOLDER/sourceFilesWritten.txt
fi

numberToDo=50
tempIDFile=$SOURCESFOLDER/IDsToDo.txt

if [ -e $tempIDFile ] ; then rm $tempIDFile; fi
doing=0
ls $SOURCESFOLDER/*.sources.txt | while read ID
do
	ID=${ID##*/}
	ID=${ID%.sources.txt}	
	if [ ! -e $FASTQFOLDER/$ID.r1.fastq.gz -o ! -e  $FASTQFOLDER/$ID.r2.fastq.gz ] 
	then
		if [ $doing -lt $numberToDo ]
		then
			echo $ID >> $tempIDFile
			doing=$(( doing + 1 ))
		else
			break
		fi
	fi
done

# echo SRR1520426 > $PROJECTDIR/SSSDNM/SRRIDs/doThese.txt
# just to check

export PIPELINENAME=sortDbGAPDownloads
export PIPELINESCRIPTSFOLDER=/home/rejudcu/pipeline_scripts
export PIPELINESCRIPTS="downloadSRAs.sh sra2fastq.sh convertDbGaPFastqs.sh"
export IDFILE=$tempIDFile

export OLDCLUSTER=no
export ATTEMPTS=1

export PIPELINEPARSFILE=$PIPELINESCRIPTSFOLDER/alignParsFile.txt

if [ ! -e $PIPELINEHOMEFOLDER/pipelinetempfolder ] ; then mkdir $PIPELINEHOMEFOLDER/pipelinetempfolder; fi

logFile=${0##*/}
logFile=$PIPELINEHOMEFOLDER/pipelinetempfolder/${logFile%.sh}.log
doing=`cat $IDFILE | wc -l`

if [ $doing -gt 0 ]
then
	# export SUBMITJOBS=no
	bash $PIPELINESCRIPTSFOLDER/buildPipeline.sh  
	echo "bash $0 &> $logFile " | at now +120 minutes
else
	echo All finished > $logFile 
fi
