# template for a script to be part of pipeline

# each line will go through a process like this so that variables get substituted:
# newline=`echo echo $line | bash`
# this mean that stuff like quotes, double quotes and escaped characters may not be dealt with correctly

# TEMPFOLDER is the place for intermediate files belonging to the script in main project space
# except for SCRATCHFOLDER all folders will be relative to PIPELINEHOMEFOLDER
TEMPFOLDER=sra2fastqtemp

# INPUTFOLDER is folder where to find input files, relative to $PIPELINEHOMEFOLDERn
INPUTFOLDER=sra

# INPUTFILES is spec of input files in $PIPELINEHOMEFOLDER/$INPUTFOLDER (can have wildcards, usually will have $ID in it)
INPUTFILES=${ID}.sra

# OUTPUTFOLDER is folder where to find output files, relative to $PIPELINEHOMEFOLDER
OUTPUTFOLDER=fastq

# OUTPUTFILES is list of output files in $PIPELINEHOMEFOLDER/$OUTPUTFOLDER (usually will have $ID in it)
# these are all the files which should exist by the time this stage of the pipeline is complete
OUTPUTFILES="${ID}_sorted_unique.cleaned.r1.fastq.gz ${ID}_sorted_unique.cleaned.r2.fastq.gz"

# WRITTENFILES is a list of output files $PIPELINEHOMEFOLDER/$OUTPUTFOLDER actually written by this script
# if one is missing or zero length all will be deleted before the script runs
WRITTENFILES="${ID}_sorted_unique.cleaned.r1.fastq.gz ${ID}_sorted_unique.cleaned.r2.fastq.gz"
# leave out testing with gzip

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

# potentially for the exomes these could go to scratch0
scratchFolder=$PIPELINEHOMEFOLDER/$TEMPFOLDER/$ID
mkdir $scratchFolder
workFolder=$scratchFolder

rm $workFolder/*

infiles=($INPUTFILES)
outfiles=($OUTPUTFILES)
fastqfiles=(${ID}_1.fastq.gz ${ID}_2.fastq.gz )
date
echo running $fastqdump
cd /cluster/project8/bipolargenomes/downloads
# vital to cd or else none of the SRA utilities will work
$fastqdump --outdir $scratchFolder --gzip --split-3 $PIPELINEHOMEFOLDER/$INPUTFOLDER/${infiles[0]} > $scratchFolder/fastqdump.err
echo $fastqdump finished, here is output of ls -l $scratchFolder
ls -l $scratchFolder # just for debugging
echo $scratchFolder/fastqdump.err looks like this:
cat $scratchFolder/fastqdump.err
OK=yes

if [ ! -e $scratchFolder/${fastqfiles[0]} -o ! -e $scratchFolder/${fastqfiles[1]} ]
then
	OK=no
fi
if [ \$OK = yes ]
then
	countWritten=\$(fgrep -c Written $PIPELINEHOMEFOLDER/$TEMPFOLDER/$ID/fastqdump.err)
	if [ \$countWritten -eq 0 ]
	then
		OK=no
	fi
fi

if [ \$OK = no ]
then
	echo Error - $scratchFolder/${fastqfiles[0]} and $scratchFolder/${fastqfiles[1]} not written properly
else
	fastqSize1=$(stat -c%s $scratchFolder/${fastqfiles[0]})
	fastqSize2=$(stat -c%s $scratchFolder/${fastqfiles[1]})
	inSize=$(stat -c%s $PIPELINEHOMEFOLDER/$INPUTFOLDER/${infiles[0]})
	percent=$(echo "( $fastqSize1 + $fastqSize2 ) / $inSize * 100 " | bc )
	echo $inSize $fastqSize1  $fastqSize2 $percent
	mv $scratchFolder/${fastqfiles[0]} $PIPELINEHOMEFOLDER/$OUTPUTFOLDER/${outfiles[0]}
	mv $scratchFolder/${fastqfiles[1]} $PIPELINEHOMEFOLDER/$OUTPUTFOLDER/${outfiles[1]}
	# assumes they are on same file system so mv is instant - does not work if using scratch0
	rm $PIPELINEHOMEFOLDER/$INPUTFOLDER/${infiles[0]}
	rm /cluster/project8/bipolargenomes/downloads/sra/${infiles[0]}
	rm -r $scratchFolder
fi
		