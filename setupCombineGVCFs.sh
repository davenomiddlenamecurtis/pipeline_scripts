#!/bin/bash

maxToCombine=100
gVCFfolder=$PIPELINEHOMEFOLDER/gVCF

tempIDFile=$PIPELINEHOMEFOLDER/combined.gVCF.IDs.lst
rm $tempIDFile

if [ -z "$PIPELINEHOMEFOLDER" ]
then
	echo Error: Must set PIPELINEHOMEFOLDER 
	exit
fi

REALIDFILE=$PIPELINEHOMEFOLDER/combineThese.txt
if [ ! -e $REALIDFILE ]
then
	echo Error: There must be a file called $REALIDFILE containing the IDs to be combined
	exit
fi

group=1
inFile=0
ID=combined.$group
rm $gVCFfolder/$ID.lst

cat $REALIDFILE | while read gVCFID
do
	if [ $inFile -eq 0 ]
	then 
		echo $ID >> $tempIDFile
	fi
	echo $gVCFfolder/$gVCFID.gvcf.gz >> $gVCFfolder/$ID.lst
	inFile=$(( inFile + 1 ))
	if [ $inFile -eq $maxToCombine ]
	then
		inFile=0
		group=$(( group + 1 ))
		ID=combined.$group
		rm $gVCFfolder/$ID.lst
	fi
done

export PIPELINENAME=combineGVCFsPipeline
export PIPELINESCRIPTSFOLDER=/home/rejudcu/pipeline_scripts
export PIPELINESCRIPTS="combineGVCFs.sh"
export IDFILE=$tempIDFile

export ATTEMPTS=1

export PIPELINEPARSFILE=$PIPELINESCRIPTSFOLDER/alignParsFile.txt

logFile=${0##*/}
logFile=$PIPELINEHOMEFOLDER/pipelinetempfolder/${logFile%.sh}.log
doing=`cat $IDFILE | wc -l`
if [ $doing -gt 0 ]
then
	bash $PIPELINESCRIPTSFOLDER/buildPipeline.sh  
#	echo "bash $0 &> $logFile " | at now +4 hours
else
	echo All finished > $logFile 
fi
