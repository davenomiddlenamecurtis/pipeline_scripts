# template for a script to be part of pipeline
# script to move big files across systems

# TEMPFOLDER is the place for intermediate files belonging to the script in main project space
# except for SCRATCHFOLDER all folders will be relative to PIPELINEHOMEFOLDER
TEMPFOLDER=toMerge/mergeFilesTemp

# INPUTFOLDER is folder where to find input files, relative to $PIPELINEHOMEFOLDERn
INPUTFOLDER=toMerge

# INPUTFILES is spec of input files in $PIPELINEHOMEFOLDER/$INPUTFOLDER (can have wildcards, usually will have $ID in it)
INPUTFILES=$ID.toMerge.txt

# OUTPUTFOLDER is folder where to find output files, relative to $PIPELINEHOMEFOLDER
OUTPUTFOLDER=toMerge

# OUTPUTFILES is list of output files in $PIPELINEHOMEFOLDER/$OUTPUTFOLDER (usually will have $ID in it)
# these are all the files which should exist by the time this stage of the pipeline is complete
OUTPUTFILES=$ID.mergedOK.txt

# WRITTENFILES is a list of output files $PIPELINEHOMEFOLDER/$OUTPUTFOLDER actually written by this script
# if one is missing or zero length all will be deleted before the script runs
WRITTENFILES=$ID.mergedOK.txt

# HVMEM will be read and used to request hvmem for the script
HVMEM=1G
TMEM=1G
NCORES=1
SCRATCH=1G
# NHOURS 20
NHOURS=4

# COMMANDS must be at end of script and give set of commands to get from input to output files
# must be constructed so that complete output files are produced promptly, usually with a mv command
# ideally would not contain exit commands
# most scripts would do some final checks before definitively writing output files
# the pipeline script will do the following checks:
# if all output files exist and are not zero, skip the script
# if not, delete any output files
# if any input files do not exist then report error and exit
# if not all output files are created properly, report error

COMMANDS

line=`cat $PIPELINEHOMEFOLDER/$INPUTFOLDER/$INPUTFILES`
words=($line)
workFolder=$PIPELINEHOMEFOLDER/$TEMPFOLDER/$ID
mkdir $workFolder
allDone=maybe
for i in 1 2
do
	cat ${words[1]}_sorted_unique.cleaned.r${i}.fastq.gz > $workFolder/$ID.r${i}.fastq.gz
	cat ${words[3]}_sorted_unique.cleaned.r${i}.fastq.gz >> $workFolder/$ID.r${i}.fastq.gz
	gzip -t $workFolder/$ID.r${i}.fastq.gz
	if [ $? -eq 0 ]
	then
		if [ $allDone=maybe -o $allDone=yes ]
		then
			allDone=yes
		fi
		echo Merged $ID.r${i}.fastq.gz OK
	else
		allDone=no
		echo gzip reported a problem with $ID.r${1}.fastq.gz
		break
	fi
done
if [ $allDone = yes ]
then
	for i in 1 2
	do
		mv $workFolder/$ID.r${i}.fastq.gz $PROJECTDIR/SSSDNM/fastq/$ID.r${i}.fastq.gz # folder could have been specified in $ID.toMerge.txt
		rm ${words[1]}_sorted_unique.cleaned.r${i}.fastq.gz ${words[3]}_sorted_unique.cleaned.r${i}.fastq.gz
	done
	rm -r $workFolder
	echo $ID fastqs merged OK > $PIPELINEHOMEFOLDER/$OUTPUTFOLDER/$OUTPUTFILES
else
	echo Problem merging fastqs for $ID
fi
