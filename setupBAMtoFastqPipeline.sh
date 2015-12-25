#!/bin/bash

numberToDo=10
rm /cluster/project8/bipolargenomes/BPGIDs/doThese.txt
doing=0
cat /cluster/project8/bipolargenomes/BPGIDs/allBPIDs.txt | while read ID
do
	if [ -e /goon2/project99/bipolargenomes_raw/ingest/forlab/fastq/${ID}.r2.fastq.gz ] ; then continue; fi
	echo $ID >> /cluster/project8/bipolargenomes/BPGIDs/doThese.txt
	doing=$(( doing + 1 ))
	if [ $doing -ge $numberToDo ] ; then break; fi
done

export PIPELINENAME=bam2FastqPipeline
export PIPELINESCRIPTSFOLDER=/home/rejudcu/pipelineScripts
export PIPELINESCRIPTS="bam2fastq.sh compressFastq1.sh testCompressedFastq1.sh compressFastq2.sh testCompressedFastq2.sh "
# export PIPELINESCRIPTS="bam2fastq.sh"
export IDFILE=/cluster/project8/bipolargenomes/BPGIDs/doThese.txt

export OLDCLUSTER=yes
export PIPELINEHOMEFOLDER=/goon2/project99/bipolargenomes_raw/ingest/forlab
export ATTEMPTS=2

bash ~/pipelineScripts/buildPipeline.sh  
echo "bash ~/pipelineScripts/setupBAMtoFastqPipeline.sh > /goon2/project99/bipolargenomes_raw/ingest/forlab/pipelinetempfolder/setupBAMtoFastqPipeline.log " | at now +4 hours
