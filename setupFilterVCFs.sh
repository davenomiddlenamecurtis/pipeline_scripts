#!/bin/bash

if [ -z "$PIPELINEHOMEFOLDER" ]
then
	echo Error: Must set PIPELINEHOMEFOLDER 
	exit
fi

REALIDFILE=$PIPELINEHOMEFOLDER/filterThese.txt
if [ ! -e $REALIDFILE ]
then
	echo Error: There must be a file called $REALIDFILE containing the IDs to be aligned
	exit
fi

defaultNumberToDo=100
if [ "$numberToDo" = "" ]
then
	numberToDo=$defaultNumberToDo
fi

tempIDFile=$PIPELINEHOMEFOLDER/doThese.txt
if [ -e $tempIDFile ] ; then rm $tempIDFile; fi
doing=0
cat $REALIDFILE | while read ID
do
	if [ -e /$PIPELINEHOMEFOLDER/filteredVCF/${ID}.filtered.vcf.gz ] ; then continue; fi
	echo $ID >> $tempIDFile
	doing=$(( doing + 1 ))
	if [ $doing -ge $numberToDo ] ; then break; fi
done

# echo LP0022129-DNA_A01 > $PROJECTDIR/BPGIDs/doThese.txt
# just to check

export PIPELINENAME=filterVCFPipeline
export PIPELINESCRIPTSFOLDER=/home/rejudcu/pipeline_scripts
export PIPELINESCRIPTS="divideVCFByVarType.sh filterSNPs.sh filterIndels.sh combineFiltered.sh"
export IDFILE=$tempIDFile

export ATTEMPTS=1

export PIPELINEPARSFILE=$PIPELINESCRIPTSFOLDER/alignParsFile.txt

logFile=${0##*/}
logFile=$PIPELINEHOMEFOLDER/pipelinetempfolder/${logFile%.sh}.log
doing=`cat $IDFILE | wc -l`
if [ $doing -gt 0 ]
then
	bash $PIPELINESCRIPTSFOLDER/buildPipeline.sh  
	echo "bash $0 &> $logFile " | at now +4 hours
else
	echo All finished > $logFile 
fi
