#!/bin/bash

ID=SSSDNM
# specify the cohort for these VCF files

if [ -z $ID ]
then
	echo Error: Must set ID to identify cohort to assign to these VCF files (e.g. BPWGS)
fi


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

rm $gVCFfolder/$ID.lst
inFile=0
cat $REALIDFILE | while read gVCFID
do
	echo $gVCFfolder/$gVCFID.gvcf.gz >> $gVCFfolder/$ID.lst
	inFile=$(( inFile + 1 ))
done

rm $tempIDFile
for chr in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 X
do
	echo $ID.$chr >> $tempIDFile
	echo $chr > $gVCFfolder/$ID.$chr.chr
	ln -s $gVCFfolder/$ID.lst $gVCFfolder/$ID.$chr.lst
done

export PIPELINENAME=genotypeOneChrGVCFsPipeline
export PIPELINESCRIPTSFOLDER=/home/rejudcu/pipeline_scripts
export PIPELINESCRIPTS="genotypeOneChrGvcfs.sh"
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
