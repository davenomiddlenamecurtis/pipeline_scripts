#!/bin/bash

# set up pipeline analyses for IDs which have not yet completed
# this does not check qstat, but buildPipeline.sh does and will not 
# write any scripts for any IDs currently being worked on
# this means that maximum of numberToDo analyses are runnning at any time

numberToDo=50
tempIDFile=$PROJECTDIR/SSSDNM/SRRIDs/mergeThese.txt
if [ -e $tempIDFile ] ; then rm $tempIDFile; fi
doing=0
ls $PROJECTDIR/SSSDNM/toMerge/*.toMerge.txt | while read ID
do
	ID=${ID##*/}
	ID=${ID%.toMerge.txt}	
	if [ ! -e $PROJECTDIR/SSSDNM/toMerge/$ID.mergedOK.txt ] 
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

export PIPELINENAME=mergeFastqsPipeline
export PIPELINESCRIPTSFOLDER=/home/rejudcu/pipeline_scripts
# export PIPELINESCRIPTS="runNovoalign.sh removeDuplicates.sh concordantSam2Bam.sh discordantSam2Bam.sh sortConcordantBam.sh sortDiscordantBam.sh"
# export PIPELINESCRIPTS="runNovoalign.sh discordantSam2Bam.sh sortConcordantBam.sh sortDiscordantBam.sh"
export PIPELINESCRIPTS="mergeFastqs.sh"
export IDFILE=$tempIDFile

export OLDCLUSTER=no
export PIPELINEHOMEFOLDER=$PROJECTDIR/SSSDNM
export ATTEMPTS=1

export PIPELINEPARSFILE=$PIPELINESCRIPTSFOLDER/alignParsFile.txt

if [ ! -e $PIPELINEHOMEFOLDER/pipelinetempfolder ] ; then mkdir $PIPELINEHOMEFOLDER/pipelinetempfolder; fi

logFile=${0##*/}
logFile=$PIPELINEHOMEFOLDER/pipelinetempfolder/{logFile%.sh}.log
doing=`cat $IDFILE | wc -l`
if [ $doing -gt 0 ]
then
	bash $PIPELINESCRIPTSFOLDER/buildPipeline.sh  
	# echo "bash $0 &> $logFile " | at now +120 minutes
else
	echo All finished > $logFile 
fi
