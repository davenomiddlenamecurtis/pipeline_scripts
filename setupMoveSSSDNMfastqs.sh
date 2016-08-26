#!/bin/bash

REALIDFILE=$PROJECTDIR/SSSDNM/SRRIDs/SSSDNMfastq2move.txt
export IDFILE=$PROJECTDIR/SSSDNM/SRRIDs/SSSDNMfastq2moveToDo.txt
export FROMFOLDER=/goon2/project99/bipolargenomes_raw/forlab/SSSDNM/fastq
export TOFOLDER=$PROJECTDIR/SSSDNM/fastq
export PIPELINENAME=moveSSSDNMfastqs

numberToDo=100
rm $IDFILE
doing=0
cat $REALIDFILE | while read ID
do
	if [ -e /$TOFOLDER/$ID ] ; then continue; fi
	echo $ID >> $IDFILE
	doing=$(( doing + 1 ))
	if [ $doing -ge $numberToDo ] ; then break; fi
done

# echo SRR1253977.r2.fastq.gz > $IDFILE
# just to check

export PIPELINETEMPFOLDER=$TOFOLDER/pipelinetempmovefolder
export ATTEMPTS=1

export PIPELINESCRIPTSFOLDER=/home/rejudcu/pipeline_scripts
export PIPELINESCRIPTS="moveFiles.sh"
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
