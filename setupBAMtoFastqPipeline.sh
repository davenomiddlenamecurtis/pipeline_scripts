#!/bin/bash

if [ -z "$PIPELINEHOMEFOLDER" ]
then
	echo Error: Must set PIPELINEHOMEFOLDER 
	exit
fi

numberToDo=10
TEMPIDFILE=extractTheseTemp.txt
rm $TEMPIDFILE
doing=0
cat $PIPELINEHOMEFOLDER/extractThese.txt | while read ID
do
	# if [ -e /goon2/project99/bipolargenomes_raw/ingest/forlab/fastq/${ID}.r2.fastq.gz ] ; then continue; fi
	if [ -e $PIPELINEHOMEFOLDER/fastq/${ID}.r2.fastq.gz ] ; then continue; fi
	echo $ID >> $TEMPIDFILE
	doing=$(( doing + 1 ))
	if [ $doing -ge $numberToDo ] ; then break; fi
done

export PIPELINENAME=bam2FastqPipeline
export PIPELINESCRIPTSFOLDER=/home/rejudcu/pipeline_scripts
export PIPELINEPARSFILE=$PIPELINESCRIPTSFOLDER/alignParsFile.txt

export PIPELINESCRIPTS="bam2fastq.sh compressFastq1.sh testCompressedFastq1.sh compressFastq2.sh testCompressedFastq2.sh "
# export IDFILE=$PROJECTDIR/BPGIDs/doThese.txt
export IDFILE=$TEMPIDFILE

export OLDCLUSTER=no
# export PIPELINEHOMEFOLDER=/goon2/project99/bipolargenomes_raw/ingest/forlab
export ATTEMPTS=2

logFile=${0##*/}
logFile=$PIPELINEHOMEFOLDER/pipelinetempfolder/${logFile%.sh}.log

bash $PIPELINESCRIPTSFOLDER/buildPipeline.sh  
echo "bash $0 &> $logFile " | at now +1 hours
# maybe 4 hours for genomes
