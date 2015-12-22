# template for a script to be part of pipeline

# each line will go through a process like this so that variables get substituted:
# newline=`echo echo $line | bash`
# this mean that stuff like quotes, double quotes and escaped characters may not be dealt with correctly

# TEMPFOLDER is the place for intermediate files belonging to the script in main project space
# except for SCRATCHFOLDER all folders will be relative to PIPELINEHOMEFOLDER
TEMPFOLDER=compressfastqtemp

# INPUTFOLDER is folder where to find input files, relative to $PIPELINEHOMEFOLDERn
INPUTFOLDER=fastq

# INPUTFILES is spec of input files in $PIPELINEHOMEFOLDER/$INPUTFOLDER (can have wildcards, usually will have $ID in it)
INPUTFILES="${ID}_sorted_unique.cleaned.r1.fastq.nottested.gz ${ID}_sorted_unique.cleaned.r1.fastq ${ID}_sorted_unique.cleaned.r2.fastq"

# OUTPUTFOLDER is folder where to find output files, relative to $PIPELINEHOMEFOLDER
OUTPUTFOLDER=fastq

# OUTPUTFILES is list of output files in $PIPELINEHOMEFOLDER/$OUTPUTFOLDER (usually will have $ID in it)
# these are all the files which should exist by the time this stage of the pipeline is complete
OUTPUTFILES="${ID}_sorted_unique.cleaned.r1.fastq.gz.waitingforr2 ${ID}_sorted_unique.cleaned.r2.fastq"

# WRITTENFILES is a list of output files $PIPELINEHOMEFOLDER/$OUTPUTFOLDER actually written by this script
# if one is missing or zero length all will be deleted before the script runs
WRITTENFILES="${ID}_sorted_unique.cleaned.r1.fastq.gz.waitingforr2"

# HMEM will be read and used to request hmem for the script
HMEM=1G

NCORES=1
SCRATCH=1G
NHOURS=10


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

infiles=($INPUTFILES)
outfiles=($OUTPUTFILES)
cd $PIPELINEHOMEFOLDER/$INPUTFOLDER
gzip -t ${infiles[0]}
if [ $? -eq 0 ]
then
	mv ${infiles[0]} $PIPELINEHOMEFOLDER/$OUTPUTFOLDER/${outfiles[0]} # though there is only one
	rm ${infiles[1]}
else
	echo ${infiles[0]} failed gzip -t so was removed
	rm ${infiles[0]}
fi
	


