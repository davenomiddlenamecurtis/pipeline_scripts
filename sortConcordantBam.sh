# template for a script to be part of pipeline

# TEMPFOLDER is the place for intermediate files belonging to the script in main project space
# except for SCRATCHFOLDER all folders will be relative to PIPELINEHOMEFOLDER
TEMPFOLDER=fastq2bamtemp

# INPUTFOLDER is folder where to find input files, relative to $PIPELINEHOMEFOLDERn
INPUTFOLDER=fastq

# INPUTFOLDER is folder where to find input files, relative to $PIPELINEHOMEFOLDERn
INPUTFOLDER=sam

# INPUTFILES is spec of input files in $PIPELINEHOMEFOLDER/$INPUTFOLDER (can have wildcards, usually will have $ID in it)
INPUTFILES="${ID}_conc.bam ${ID}_disc.bam"

# OUTPUTFOLDER is folder where to find output files, relative to $PIPELINEHOMEFOLDER
OUTPUTFOLDER=sam

# OUTPUTFILES is list of output files in $PIPELINEHOMEFOLDER/$OUTPUTFOLDER (usually will have $ID in it)
# these are all the files which should exist by the time this stage of the pipeline is complete
OUTPUTFILES="${ID}_sorted_unique.bam ${ID}_sorted_unique.bam.bai ${ID}_disc.bam"

# WRITTENFILES is a list of output files $PIPELINEHOMEFOLDER/$OUTPUTFOLDER actually written by this script
# if one is missing or zero length all will be deleted before the script runs
WRITTENFILES="${ID}_sorted_unique.bam ${ID}_sorted_unique.bam.bai" 

# HVMEM will be read and used to request hvmem for the script
HVMEM=8G
TMEM=8G
# these were 3 G

# neeed more memory to run java
NCORES=6
SCRATCH=1G
NHOURS=240


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

# variables for alignment:
memory2=7
ncores=$NCORES
extraID=$ID
# it looks like when I added read groups I used SM=$code, which should set the group name to the ID
tparam=250
inputFormat=STDFQ
reference=1kg

tempFolder=$PIPELINEHOMEFOLDER/$TEMPFOLDER
# might be on scratch

infiles=($INPUTFILES)
outfiles=($outfiles)
date
mkdir $tempFolder
mkdir $tempFolder/$ID
$novosort -t $tempFolder/$ID -c ${ncores} -m ${memory2}G -i -o $PIPELINEHOMEFOLDER/$TEMPFOLDER/$ID/${outfiles[0]} $PIPELINEHOMEFOLDER/$INPUTFOLDER/${infiles[0]} > $PIPELINEHOMEFOLDER/$TEMPFOLDER/$ID/${outfiles[0]} 2> $PIPELINEHOMEFOLDER/$TEMPFOLDER/$ID/novosort.err
OK=yes
if [ -e $PIPELINEHOMEFOLDER/$TEMPFOLDER/$ID/${outfiles[1]} -a -s $PIPELINEHOMEFOLDER/$TEMPFOLDER/$ID/${outfiles[1]} ]
then
	$samtools idxstats $PIPELINEHOMEFOLDER/$TEMPFOLDER/$ID/${outfiles[0]} > $PIPELINEHOMEFOLDER/$TEMPFOLDER/$ID/idxstats.txt
	truncCount==$(fgrep -c truncated $PIPELINEHOMEFOLDER/$TEMPFOLDER/$ID/idxstats.txt)
	if [ \$truncCount -gt 0 ]
	then
		OK=no
		echo Problem running $novosort, samtools reports that $PIPELINEHOMEFOLDER/$TEMPFOLDER/$ID/${outfiles[0]} is truncated
	fi
else
	OK=no
fi
if [ \$OK = yes ]
then
	mv $PIPELINEHOMEFOLDER/$TEMPFOLDER/$ID/${outfiles[0]} $PIPELINEHOMEFOLDER/$OUTPUTFOLDER/${outfiles[0]}
	mv $PIPELINEHOMEFOLDER/$TEMPFOLDER/$ID/${outfiles[1]} $PIPELINEHOMEFOLDER/$OUTPUTFOLDER/${outfiles[1]}
	# rm $PIPELINEHOMEFOLDER/$INPUTFOLDER/$ID/${infiles[0]} 
else 
	echo Error: $PIPELINEHOMEFOLDER/$TEMPFOLDER/$ID/${outfiles[0]} and $PIPELINEHOMEFOLDER/$TEMPFOLDER/$ID/${outfiles[1]} were not written correctly
fi
# do checks then
# rm $PIPELINEHOMEFOLDER/$INPUTFOLDER/${INPUTFILES[0]}

date
		