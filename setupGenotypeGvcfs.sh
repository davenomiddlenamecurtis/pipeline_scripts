#!/bin/bash

maxToCombine=100
gVCFfolder=$PIPELINEHOMEFOLDER/combinedGVCF

tempIDFile=$PIPELINEHOMEFOLDER/combined.gVCF.IDs.lst
rm $tempIDFile

if [ -z "$PIPELINEHOMEFOLDER" ]
then
	echo Error: Must set PIPELINEHOMEFOLDER 
	exit
fi

REALIDFILE=$PIPELINEHOMEFOLDER/genotypeThese.txt
if [ ! -e $REALIDFILE ]
then
	echo Error: There must be a file called $REALIDFILE containing the IDs to be combined
	exit
fi

ID=SSSDNM
rm $gVCFfolder/$ID.lst
inFile=0

cat $REALIDFILE | while read gVCFID
do
	if [ $inFile -eq 0 ]
	then 
		echo $ID >> $tempIDFile
	fi
	echo $gVCFfolder/$gVCFID.gvcf.gz >> $gVCFfolder/$ID.lst
	inFile=$(( inFile + 1 ))
done

export PIPELINENAME=genotypeGVCFsPipeline
export PIPELINESCRIPTSFOLDER=/home/rejudcu/pipeline_scripts
export PIPELINESCRIPTS="genotypeGvcfs.sh"
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
