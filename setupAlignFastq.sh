#!/bin/bash

if [ -z "$PIPELINEHOMEFOLDER" ]
then
	echo Error: Must set PIPELINEHOMEFOLDER 
	exit
fi

REALIDFILE=$PIPELINEHOMEFOLDER/alignThese.txt
if [ ! -e $REALIDFILE ]
then
	echo Error: There must be a file called $REALIDFILE containing the IDs to be aligned
	exit
fi

defaultNumberToDo=100
if [ "$numberToDo" = "" ]
then
	numberToDo=$defaultNumberToDo
fi

tempIDFile=$PIPELINEHOMEFOLDER/doThese.txt
if [ -e $tempIDFile ] ; then rm $tempIDFile; fi
doing=0
cat $REALIDFILE | while read ID
do
	if [ -e /$PIPELINEHOMEFOLDER/bam/${ID}_disc_sorted.bam.bai ] ; then continue; fi
	echo $ID >> $tempIDFile
	doing=$(( doing + 1 ))
	if [ $doing -ge $numberToDo ] ; then break; fi
done

# echo LP0022129-DNA_A01 > $PROJECTDIR/BPGIDs/doThese.txt
# just to check

export PIPELINENAME=alignFastqPipeline
export PIPELINESCRIPTSFOLDER=/home/rejudcu/pipeline_scripts
# export PIPELINESCRIPTS="runNovoalign.sh removeDuplicates.sh concordantSam2Bam.sh discordantSam2Bam.sh sortConcordantBam.sh sortDiscordantBam.sh"
# export PIPELINESCRIPTS="runNovoalign.sh discordantSam2Bam.sh sortConcordantBam.sh sortDiscordantBam.sh"
export PIPELINESCRIPTS="runNovoalign.with.unpaired.sh discordantSam2Bam.sh sortConcordantBam.sh sortDiscordantBam.sh"
export IDFILE=$tempIDFile

export ATTEMPTS=1

export PIPELINEPARSFILE=$PIPELINESCRIPTSFOLDER/alignParsFile.txt

logFile=${0##*/}
logFile=$PIPELINEHOMEFOLDER/pipelinetempfolder/${logFile%.sh}.log
doing=`cat $IDFILE | wc -l`
# because doing was inside a loop in a different bash shell
if [ $doing -gt 0 ]
then
	bash $PIPELINESCRIPTSFOLDER/buildPipeline.sh  
	echo "bash $0 &> $logFile " | at now +10 hours
else
	echo All finished > $logFile 
fi
