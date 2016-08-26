#!/bin/bash

export FROMFOLDER=$PROJECTDIR/BPgenomes/bam
export TOFOLDER=/cluster/project99/bipolargenomes_raw/forlab/bam
# export TOFOLDER=/goon2/project99/bipolargenomes_raw/forlab/SSSDNM/bam
# export TOFOLDER=$PROJECTDIR/BPgenomes/fastq
export PIPELINETEMPFOLDER=$TOFOLDER/pipelinetempmovefolder
export numberToDo=100
REALIDFILE=$PROJECTDIR/BPgenomes/moveThese.txt

tempIDFile=$TOFOLDER/tempMoveThese.txt
logFile=${0##*/}
logFile=$PIPELINETEMPFOLDER/${logFile%.sh}.log

rm $tempIDFile
doing=0
cat $REALIDFILE | while read ID
do
	if [ -e $TOFOLDER/$ID ] ; then continue; fi
	echo $ID >> $tempIDFile
	doing=$(( doing + 1 ))
	if [ $doing -ge $numberToDo ] ; then break; fi
done

export IDFILE=$tempIDFile

# echo SRR1776872.r1.fastq.gz > $PROJECTDIR/SSSDNM/SRRIDs/moveThese.txt
# just to check

export ATTEMPTS=1

export PIPELINENAME=moveBams
export PIPELINESCRIPTSFOLDER=/home/rejudcu/pipeline_scripts
export PIPELINESCRIPTS="moveFiles.sh"
export PIPELINEHOMEFOLDER=/

doing=`cat $IDFILE | wc -l`
if [ $doing -gt 0 ]
then
	bash ~/pipeline_scripts/buildPipeline.sh  
	echo "bash $0 &> $logFile " | at now +60 minutes
else
	echo All finished > $logFile
fi
