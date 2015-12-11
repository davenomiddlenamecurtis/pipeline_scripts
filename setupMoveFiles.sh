#!/bin/bash

numberToDo=100
rm /cluster/project8/bipolargenomes/SSSDNM/SRRIDs/moveThese.txt
doing=0
cat /cluster/project8/bipolargenomes/SSSDNM/SRRIDs/toMove.txt | while read ID
do
	if [ -e /cluster/scratch4/rejudcu_scratch/SSSDNM/fastq/$ID ] ; then continue; fi
	echo $ID >> /cluster/project8/bipolargenomes/SSSDNM/SRRIDs/moveThese.txt
	doing=$(( doing + 1 ))
	if [ $doing -ge $numberToDo ] ; then break; fi
done

echo SRR1463469_sorted_unique.cleaned.r1.fastq.gz > /cluster/project8/bipolargenomes/SSSDNM/SRRIDs/moveThese.txt
# just to check

export PIPELINENAME=moveFastqs
export PIPELINESCRIPTSFOLDER=/home/rejudcu/pipelineScripts
export PIPELINESCRIPTS="moveFiles.sh"
export IDFILE=/cluster/project8/bipolargenomes/SSSDNM/SRRIDs/moveThese.txt
export OLDCLUSTER=yes
export PIPELINEHOMEFOLDER=/
export ATTEMPTS=1
export PIPELINETEMPFOLDER=/cluster/project8/bipolargenomes/pipelinetempmovefolder

doing=`cat $IDFILE | wc -l`
if [ $doing -gt 0 ]
then
	bash ~/pipelineScripts/buildPipeline.sh  
	echo "bash ~/pipelineScripts/setupMoveFiles.sh &> /cluster/project8/bipolargenomes/pipelinetempmovefolder/setupMoveFiles.log " | at now +30 minutes
else
	echo All finished > /cluster/project8/bipolargenomes/pipelinetempmovefolder/setupMoveFiles.log 
fi
