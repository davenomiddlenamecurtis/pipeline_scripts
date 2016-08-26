#!/bin/bash
IDFILE=$PROJECTDIR/BPGIDs/BPGIDs.txt
SCRIPTNUMBER=2

# script to build and submit pipeline scripts
# Usage:
# Need to set these environment variables:
# PIPELINENAME - name of pipeline
# PIPELINESCRIPTSFOLDER - folder for the scripts below
# PIPELINESCRIPTS - list of scripts in order to be applied to each ID
# IDFILE - full path of file containing IDs

# Following are optional:
# ATTEMPTS - number of times to loop round the pipeline
# PIPELINEHOMEFOLDER

DEFAULTHVMEM=1G
DEFAULTTMEM=1G
DEFAULTNCORES=1
DEFAULTSCRATCH=1G
DEFAULTNHOURS=3
DELETEINTERMEDIATES=no 
DEFAULTATTEMPTS=1

NVARIABLESFORSCRIPTS=0
if [ ! -z "$PIPELINEPARSFILE" ]
then
cat $PIPELINEPARSFILE | while read line
do
	line=${line//=/ }
	echo line | read first rest
	$first=$rest
	VARIABLESFORSCRIPTS[NVARIABLESFORSCRIPTS]=$first
	NVARIABLESFORSCRIPTS=$((NVARIABLESFORSCRIPTS+1))
done
endif


