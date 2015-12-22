# template for a script to be part of pipeline
# script to move big files across systems

# TEMPFOLDER is the place for intermediate files belonging to the script in main project space
# except for SCRATCHFOLDER all folders will be relative to PIPELINEHOMEFOLDER
TEMPFOLDER=$TOFOLDER/moveFilesTemp

# INPUTFOLDER is folder where to find input files, relative to $PIPELINEHOMEFOLDERn
INPUTFOLDER=$FROMFOLDER

# INPUTFILES is spec of input files in $PIPELINEHOMEFOLDER/$INPUTFOLDER (can have wildcards, usually will have $ID in it)
INPUTFILES=$ID

# OUTPUTFOLDER is folder where to find output files, relative to $PIPELINEHOMEFOLDER
OUTPUTFOLDER=$TOFOLDER

# OUTPUTFILES is list of output files in $PIPELINEHOMEFOLDER/$OUTPUTFOLDER (usually will have $ID in it)
# these are all the files which should exist by the time this stage of the pipeline is complete
OUTPUTFILES=$ID

# WRITTENFILES is a list of output files $PIPELINEHOMEFOLDER/$OUTPUTFOLDER actually written by this script
# if one is missing or zero length all will be deleted before the script runs
WRITTENFILES=$ID

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

if [ $PIPELINEHOMEFOLDER != / ]
then
	echo PIPELINEHOMEFOLDER must be /
	exit
fi

if [  $INPUTFOLDER = / ]
then
	echo must set FROMFOLDER in order to set INPUTFOLDER correctly
	exit
fi

if [  $OUTPUTFOLDER = / ]
then
	echo must set TOFOLDER in order to set OUTPUTFOLDER correctly
	exit
fi

if [ ! -e $INPUTFOLDER ]
then
	echo INPUTFOLDER $INPUTFOLDER does not exist 
	exit
fi

if [ ! -e $OUTPUTFOLDER ]
then
	mkdir $OUTPUTFOLDER 
	if [ ! -e $OUTPUTFOLDER ]
	then
		echo could not create /OUTPUTFOLDER $OUTPUTFOLDER 
		exit
	fi
fi

cd $PIPELINEHOMEFOLDER/$INPUTFOLDER
for f in $INPUTFILES
do
	cp $f $PIPELINEHOMEFOLDER/$TEMPFOLDER/$f
done

OK=yes
for f in $INPUTFILES
do
	inSize=0
	outSize=0
	inSize=$(stat -c%s $f)
	outSize=$(stat -c%s $PIPELINEHOMEFOLDER/$TEMPFOLDER/$f)
	if [ $inSize != $outSize ] 
	then
		OK=no
		echo $f was not copied correctly
	fi
done

if [ $OK = yes ]
then
	for f in $INPUTFILES
	do
		mv $PIPELINEHOMEFOLDER/$TEMPFOLDER/$f $PIPELINEHOMEFOLDER/$OUTPUTFOLDER/$f
		chmod 444 $PIPELINEHOMEFOLDER/$OUTPUTFOLDER/$f
	done
	for f in $INPUTFILES
	do
		chmod 700 $f
		rm $f
	done
fi

