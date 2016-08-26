# template for a script to be part of pipeline

# each line will go through a process like this so that variables get substituted:
# newline=`echo echo $line | bash`
# this mean that stuff like quotes, double quotes and escaped characters may not be dealt with correctly

# TEMPFOLDER is the place for intermediate files belonging to the script in main project space
# except for SCRATCHFOLDER all folders will be relative to PIPELINEHOMEFOLDER
TEMPFOLDER=downloadsrastemp

# INPUTFOLDER is folder where to find input files, relative to $PIPELINEHOMEFOLDERn
INPUTFOLDER=sources

# INPUTFILES is spec of input files in $PIPELINEHOMEFOLDER/$INPUTFOLDER (can have wildcards, usually will have $ID in it)
INPUTFILES=${ID}.sources.txt

# OUTPUTFOLDER is folder where to find output files, relative to $PIPELINEHOMEFOLDER
OUTPUTFOLDER=sources

# OUTPUTFILES is list of output files in $PIPELINEHOMEFOLDER/$OUTPUTFOLDER (usually will have $ID in it)
# these are all the files which should exist by the time this stage of the pipeline is complete
OUTPUTFILES=${ID}.downloadedOK.txt

# WRITTENFILES is a list of output files $PIPELINEHOMEFOLDER/$OUTPUTFOLDER actually written by this script
# if one is missing or zero length all will be deleted before the script runs
WRITTENFILES=${ID}.downloadedOK.txt

# HVMEM will be read and used to request hvmem for the script
HVMEM=8G
TMEM=8G
# I increased this from 2 to see if it would stop dumpfastq silently failing
# need more memory to run java
NCORES=1
SCRATCH=4G
# NHOURS 20
NHOURS=8


# COMMANDS must be at end of script and give set of commands to get from input to output files
# must be constructed so that complete output files are produced promptly, usually with a mv commands
# must NOT contain exit commands
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

rm $workFolder/*
if [ "$DBGAPDOWNLOADFOLDER" = "" ]
then
	echo Error in $0, must set DBGAPDOWNLOADFOLDER for fastqdump to work
	exit
fi

cd $DBGAPDOWNLOADFOLDER
# vital to cd or else none of the SRA utilities will work

OK=yes
line=`cat $PIPELINEHOMEFOLDER/$INPUTFOLDER/$INPUTFILES`
words=($line)
for (( i=1 ; i<${#words[@]} ; ++i ))
do
	if [ $OK = no ] ; then break; fi
	sra=${words[$i]}
	date
	echo running $prefetch $sra
	$prefetch $sra
	date
	if [ ! -e $DBGAPDOWNLOADFOLDER/sra/$sra.sra ]
	then
		OK=no
		Echo error in $0, did not create file $DBGAPDOWNLOADFOLDER/sra/$sra.sra
		break
	fi
	if [ ! -s $DBGAPDOWNLOADFOLDER/sra/$sra.sra ]
	then
		OK=no
		Echo error in $0, file $DBGAPDOWNLOADFOLDER/sra/$sra.sra is empty
		break
	fi
done
if [ $OK = yes ] # move sra files
then
	for (( i=1 ; i<${#words[@]} ; ++i ))
	do
		sra=${words[$i]}
		mv $DBGAPDOWNLOADFOLDER/sra/$sra.sra $PIPELINEHOMEFOLDER/$SRAFOLDER/$sra.sra
	done
	echo $line > $PIPELINEHOMEFOLDER/$OUTPUTFOLDER/$OUTPUTFILES # ID SRA1 SRA2
fi
