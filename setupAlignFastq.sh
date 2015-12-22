#!/bin/bash

numberToDo=20
rm /cluster/project8/bipolargenomes/BPGIDs/doThese.txt
doing=0
cat /cluster/project8/bipolargenomes/BPGIDs/allBPIDs.txt | while read ID
do
	if [ -e /goon2/project99/bipolargenomes_raw/forlab/bam/${ID}_disc_sorted.bam.bai ] ; then continue; fi
	echo $ID >> /cluster/project8/bipolargenomes/BPGIDs/doThese.txt
	doing=$(( doing + 1 ))
	if [ $doing -ge $numberToDo ] ; then break; fi
done

# echo LP0022129-DNA_A01 > /cluster/project8/bipolargenomes/BPGIDs/doThese.txt
# just to check

export PIPELINENAME=alignFastqPipeline
export PIPELINESCRIPTSFOLDER=/home/rejudcu/pipeline_scripts
# export PIPELINESCRIPTS="runNovoalign.sh removeDuplicates.sh concordantSam2Bam.sh discordantSam2Bam.sh sortConcordantBam.sh sortDiscordantBam.sh"
export PIPELINESCRIPTS="runNovoalign.sh discordantSam2Bam.sh sortConcordantBam.sh sortDiscordantBam.sh"
export IDFILE=/cluster/project8/bipolargenomes/BPGIDs/doThese.txt

export OLDCLUSTER=yes
export PIPELINEHOMEFOLDER=/goon2/project99/bipolargenomes_raw/forlab
export ATTEMPTS=1

export PIPELINEPARSFILE=$PIPELINESCRIPTSFOLDER/alignParsFile.txt

bash ~/pipeline_scripts/buildPipeline.sh  
echo "bash ~/pipeline_scripts/setupAlignFastq.sh > /goon2/project99/bipolargenomes_raw/forlab/pipelinetempfolder/setupAlignFastq.log " | at now +12 hours
