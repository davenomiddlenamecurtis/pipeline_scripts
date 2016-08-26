#!/bin/bash

# specifically to move bams to scratch3
# just the ones which are not already there or in forlab/bam
# folder in project space has links to both these places

REALIDFILE=$PROJECTDIR/SSSDNM/realBamFilesToMove.txt
export IDFILE=$PROJECTDIR/SSSDNM/bamFilesToMove.txt
export FROMFOLDER=$PROJECTDIR/SSSDNM/bam
export TOFOLDER=/cluster/scratch4/rejudcu_scratch/SSSDNM/bam
export PIPELINENAME=moveSSSDNMBams

numberToDo=50
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

export OLDCLUSTER=no
export PIPELINETEMPFOLDER=$TOFOLDER/pipelinetempmovefolder
export ATTEMPTS=1

export PIPELINESCRIPTSFOLDER=/home/rejudcu/pipeline_scripts
export PIPELINESCRIPTS="moveFilesAndLink.sh"
export PIPELINEHOMEFOLDER=/

if [ ! -e $PIPELINETEMPFOLDER ] ; then mkdir $PIPELINETEMPFOLDER; fi

doing=`cat $IDFILE | wc -l`
if [ $doing -gt 0 ]
then
	bash ~/pipeline_scripts/buildPipeline.sh  
	echo "bash $0 &> $PIPELINETEMPFOLDER/setupMoveSSSDNMFiles.log " | at now +60 minutes
else
	echo All finished > $PIPELINETEMPFOLDER/setupMoveSSSDNMFiles.log 
fi
