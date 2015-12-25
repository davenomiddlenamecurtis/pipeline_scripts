#!/bin/bash

numberToDo=50
rm /cluster/project8/bipolargenomes/SSSDNM/SRRIDs/doThese.txt
rm /cluster/project8/bipolargenomes/SSSDNM/SRRIDs/getThese.txt
doing=0
cat /cluster/project8/bipolargenomes/SSSDNM/SRRIDs/downloaded241215.txt | while read ID
do
	if [ ! -e /cluster/project8/bipolargenomes/SSSDNM/fastq/${ID}.r1.fastq.gz -o ! -e /cluster/project8/bipolargenomes/SSSDNM/fastq/${ID}.r2.fastq.gz ] 
	then
		ls /cluster/project8/bipolargenomes/SSSDNM/sra/$ID.sra 
		if [ -e /cluster/project8/bipolargenomes/SSSDNM/sra/$ID.sra ]
		then
			if [ $doing -lt $numberToDo ]
			then
				echo $ID >> /cluster/project8/bipolargenomes/SSSDNM/SRRIDs/doThese.txt
				ls -l /cluster/project8/bipolargenomes/SSSDNM/SRRIDs/doThese.txt
				doing=$(( doing + 1 ))
			fi
		else
			echo $ID >> /cluster/project8/bipolargenomes/SSSDNM/SRRIDs/getThese.txt
		fi
	else
	ls -l /cluster/project8/bipolargenomes/SSSDNM/fastq/${ID}.r?.fastq.gz
	fi
#	if [ -e /cluster/project8/bipolargenomes/SSSDNM/fastq/${ID}.r2.fastq.gz ] ; then continue; fi
done

# echo SRR1520426 > /cluster/project8/bipolargenomes/SSSDNM/SRRIDs/doThese.txt
# just to check

export PIPELINENAME=alignSraPipeline
export PIPELINESCRIPTSFOLDER=/home/rejudcu/pipeline_scripts
# export PIPELINESCRIPTS="runNovoalign.sh removeDuplicates.sh concordantSam2Bam.sh discordantSam2Bam.sh sortConcordantBam.sh sortDiscordantBam.sh"
# export PIPELINESCRIPTS="runNovoalign.sh discordantSam2Bam.sh sortConcordantBam.sh sortDiscordantBam.sh"
export PIPELINESCRIPTS="sra2fastq.sh"
export IDFILE=/cluster/project8/bipolargenomes/SSSDNM/SRRIDs/doThese.txt

export OLDCLUSTER=no
export PIPELINEHOMEFOLDER=/cluster/project8/bipolargenomes/SSSDNM
export ATTEMPTS=1

export PIPELINEPARSFILE=$PIPELINESCRIPTSFOLDER/alignParsFile.txt

doing=`cat $IDFILE | wc -l`
if [ $doing -gt 0 ]
then
	bash ~/pipeline_scripts/buildPipeline.sh  
	# echo "bash ~/pipeline_scripts/setupAlignSra.sh &> /cluster/project8/bipolargenomes/SSSDNM/pipelinetempfolder/setupAlignSra.log " | at now +30 minutes
else
	echo All finished > /cluster/project8/bipolargenomes/SSSDNM/pipelinetempfolder/setupAlignSra.log 
fi
