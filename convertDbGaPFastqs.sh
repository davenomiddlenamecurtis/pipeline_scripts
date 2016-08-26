# template for a script to be part of pipeline
# script to move big files across systems

# TEMPFOLDER is the place for intermediate files belonging to the script in main project space
# except for SCRATCHFOLDER all folders will be relative to PIPELINEHOMEFOLDER
TEMPFOLDER=convertfastqs

# INPUTFOLDER is folder where to find input files, relative to $PIPELINEHOMEFOLDERn
INPUTFOLDER=sources

# INPUTFILES is spec of input files in $PIPELINEHOMEFOLDER/$INPUTFOLDER (can have wildcards, usually will have $ID in it)
INPUTFILES=${ID}.extractedOK.txt

# OUTPUTFOLDER is folder where to find output files, relative to $PIPELINEHOMEFOLDER
OUTPUTFOLDER=fastq

# OUTPUTFILES is list of output files in $PIPELINEHOMEFOLDER/$OUTPUTFOLDER (usually will have $ID in it)
# these are all the files which should exist by the time this stage of the pipeline is complete
OUTPUTFILES="$ID.r1.fastq.gz $ID.r2.fastq.gz"




# WRITTENFILES is a list of output files $PIPELINEHOMEFOLDER/$OUTPUTFOLDER actually written by this script
# if one is missing or zero length all will be deleted before the script runs
WRITTENFILES="$ID.r1.fastq.gz $ID.r2.fastq.gz"

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

# I am going to use these fixed names for the intermediate folders I will need
DOWNLOADEDFASTQFOLDER=downloadedFastqs
SRAFOLDER=sra

line=`cat $PIPELINEHOMEFOLDER/$INPUTFOLDER/$INPUTFILES`
words=($line)
workFolder=$PIPELINEHOMEFOLDER/$TEMPFOLDER/$ID
if [ ! -e $workFolder ] ; then mkdir $workFolder; fi

outfiles=($OUTPUTFILES)
if [ ${#words[@]} -eq  2 ]
then
	sra=${words[1]}
	for (( r=0; r<2; ++r ))
	do
		mv $PIPELINEHOMEFOLDER/$DOWNLOADEDFASTQFOLDER/$sra.r$(($r+1)).fastq.gz $PIPELINEHOMEFOLDER/$OUTPUTFOLDER/${outfiles[$r]}
	done
else
	rm -f $workFolder/$OUTPUTFILES # just to be sure
	for (( r=0; r<2; ++r ))
	do
		mv $PIPELINEHOMEFOLDER/$DOWNLOADEDFASTQFOLDER/$sra.r$(($r+1)).fastq.gz $PIPELINEHOMEFOLDER/$OUTPUTFOLDER/${outfiles[$r]}
	done
	allDone=maybe
	for (( i=1 ; i<${#words[@]} ; ++i ))
	do
		sra=${words[$i]}
		for (( r=0; r<2; ++r ))
		do
			cat $PIPELINEHOMEFOLDER/$DOWNLOADEDFASTQFOLDER/$sra.r$(($r+1)).fastq.gz >> $workFolder/${outfiles[$r]}
		done
	done
	for (( r=0; r<2; ++r ))
	do
		gzip -t $workFolder/${outfiles[$r]}
		if [ $? -eq 0 ]
		then
			if [ $allDone=maybe -o $allDone=yes ]
			then
				allDone=yes
			fi
			echo Merged ${outfiles[$r]} OK
		else
			allDone=no
			echo gzip reported a problem with ${outfiles[$r]}
		fi
	done
	if [ $allDone = yes ]
	then
		for (( r=0; r<2; ++r ))
		do
			mv $workFolder/${outfiles[$r]} $PIPELINEHOMEFOLDER/$OUTPUTFOLDER/${outfiles[$r]}
		done
		rm -r $workFolder
	else
		echo Problem merging fastqs for $ID
	fi
fi
