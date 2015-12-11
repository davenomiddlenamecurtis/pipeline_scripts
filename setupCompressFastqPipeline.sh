#!/bin/bash

numberToDo=5
rm /cluster/project8/bipolargenomes/BPGIDs/doThese.txt
doing=0
cat /cluster/project8/bipolargenomes/BPGIDs/BPGIDs.txt | while read ID
do
	if [ -e /cluster/project8/bipolargenomes/fastq/${ID}_sorted_unique.cleaned.r2.fastq.gz ] ; then continue; fi
	echo $ID >> /cluster/project8/bipolargenomes/BPGIDs/doThese.txt
	doing=$(( doing + 1 ))
	if [ $doing -ge $numberToDo ] ; then break; fi
done

export PIPELINENAME=compressFastq
export PIPELINESCRIPTSFOLDER=/home/rejudcu/pipelineScripts
export PIPELINESCRIPTS="compressFastq1.sh testCompressedFastq1.sh compressFastq2.sh testCompressedFastq2.sh "
# export IDFILE=/cluster/project8/bipolargenomes/BPGIDs/BPGIDs.txt
# export IDFILE=/cluster/project8/bipolargenomes/BPGIDs/one.txt
export IDFILE=/cluster/project8/bipolargenomes/BPGIDs/doThese.txt

export OLDCLUSTER=yes

export ATTEMPTS=2

bash ~/pipelineScripts/buildPipeline.sh  
echo "bash ~/pipelineScripts/setupCompressFastqPipeline.sh > setupCompressFastqPipeline.log " | at now +4 hours