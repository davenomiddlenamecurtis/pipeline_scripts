#!/bin/bash

REALIDFILE=$PROJECTDIR/BPgenomes/realBamFilesToMove.txt
export IDFILE=$PROJECTDIR/BPgenomes/bamFilesToMove.txt
export FROMFOLDER=$PROJECTDIR/BPgenomes/bam
# export TOFOLDER=/cluster/scratch4/rejudcu_scratch/BPgenomes/bam
export TOFOLDER=/cluster/project99/bipolargenomes_raw/forlab/bam
export PIPELINENAME=moveBPBams

numberToDo=10
rm $IDFILE
doing=0
cat $REALIDFILE | while read ID
do
	if [ -e /$TOFOLDER/$ID ] ; then continue; fi
	echo $ID >> $IDFILE
	doing=$(( doing + 1 ))
	if [ $doing -ge $numberToDo ] ; then break; fi
done

# echo SRR1776872.r1.fastq.gz > $IDFILE
# just to check

export PIPELINETEMPFOLDER=$TOFOLDER/pipelinetempmovefolder
mkdir $PIPELINETEMPFOLDER
export ATTEMPTS=1

export PIPELINESCRIPTSFOLDER=/home/rejudcu/pipeline_scripts
export PIPELINESCRIPTS="moveFilesAndLink.sh"
export PIPELINEHOMEFOLDER=/

if [ ! -e $PIPELINETEMPFOLDER ] ; then mkdir $PIPELINETEMPFOLDER; fi

doing=`cat $IDFILE | wc -l`
if [ $doing -gt 0 ]
then
	bash -x ~/pipeline_scripts/buildPipeline.sh  
	echo "bash $0 &> $PIPELINETEMPFOLDER/setupMoveFiles.log " | at now +60 minutes
else
	echo All finished > $PIPELINETEMPFOLDER/setupMoveFiles.log 
fi
