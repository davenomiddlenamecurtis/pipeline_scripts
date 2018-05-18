# template for a script to be part of pipeline

# bam files produced by Plagnol pipeline can have ID_disc_sorted.bam as well as ID_sorted_unique.bam
# need to convert both to fastq in unmergedFastq folder then merge them

# each line will go through a process like this so that variables get substituted:
# newline=`echo echo $line | bash`
# this mean that stuff like quotes, double quotes and escaped characters may not be dealt with correctly

# TEMPFOLDER is the place for intermediate files belonging to the script in main project space
# except for SCRATCHFOLDER all folders will be relative to PIPELINEHOMEFOLDER
TEMPFOLDER=bam2fastqtemp

# INPUTFOLDER is folder where to find input files, relative to $PIPELINEHOMEFOLDERn
# INPUTFOLDER=cleaned
INPUTFOLDER=oldBam

# INPUTFILES is spec of input files in $PIPELINEHOMEFOLDER/$INPUTFOLDER (can have wildcards, usually will have $ID in it)
INPUTFILES=${ID}_sorted_unique.bam
# INPUTFILES=${ID}.bam

# OUTPUTFOLDER is folder where to find output files, relative to $PIPELINEHOMEFOLDER
OUTPUTFOLDER=fastq

# OUTPUTFILES is list of output files in $PIPELINEHOMEFOLDER/$OUTPUTFOLDER (usually will have $ID in it)
# these are all the files which should exist by the time this stage of the pipeline is complete
OUTPUTFILES="${ID}.r1.fastq ${ID}.r2.fastq" 

# WRITTENFILES is a list of output files $PIPEqdel LINEHOMEFOLDER/$OUTPUTFOLDER actually written by this script
# if one is missing or zero length all will be deleted before the script runs
WRITTENFILES="${ID}.r1.fastq ${ID}.r2.fastq"

# HVMEM will be read and used to request hvmem for the script
HVMEM=6G
TMEM=6G
NCORES=1
SCRATCH=1G
# NHOURS 20
NHOURS=60


# COMMANDS must be at end of script and give set of commands to get from input to output files
# must be constructed so that complete output files are produced promptly, usually with a mv commands
# must NOT contain exit commands
# most scripts would do some final checks before definitively writing output files
# the pipeline script will do the following checks:
# if all output files exist and are not zero, skip the script
# if not, delete any output files
# if any input files do not exist then report error and exit
# if not all output files are created properly, report error

# files seem to be getting deleted from other folders, I do not know how
# effects would be explained if scratchFolder sometimes got set to $PIPELINEHOMEFOLDER or $PIPELINEHOMEFOLDER/oldBam
# though I do not see how this could happen

COMMANDS

picard=/cluster/project8/vyp/vincent/Software/picard-tools-1.100

# do not bother trying to use scratch0 folder because fastq files for each ID come to 300G
scratchFolder=$PIPELINEHOMEFOLDER/$TEMPFOLDER/$ID
mkdir $scratchFolder
workFolder=$scratchFolder

# rm $workFolder/*
cdcheck $scratchFolder
rm $OUTPUTFILES

for extra in _disc_sorted _sorted_unique
do
input=$ID$extra.bam
output="${ID}$extra.r1.fastq ${ID}$extra.r2.fastq" 

infiles=($input)
outfiles=($output)
rm $output
date
SAVEDOUTPUTFOLDER=$OUTPUTFOLDER
OUTPUTFOLDER=unmergedFastq
if [ -e $PIPELINEHOMEFOLDER/$OUTPUTFOLDER/${outfiles[0]} -a -e $PIPELINEHOMEFOLDER/$OUTPUTFOLDER/${outfiles[1]} ]
then
  continue # already there, will be able to jump straight to merging 
fi
if [ -e INPUT=$PIPELINEHOMEFOLDER/$INPUTFOLDER/${infiles[0]} -a extra == _disc_sorted ]
then
  continue # this is OK, file may not exist
fi
error=no
echo running $picard/SamToFastq.jar
$java17 -Djava.io.tmpdir=$scratchFolder -Xmx4g -jar \
		   $picard/SamToFastq.jar \
		   INPUT=$PIPELINEHOMEFOLDER/$INPUTFOLDER/${infiles[0]} \
		   FASTQ=$scratchFolder/${outfiles[0]}  \
		   SECOND_END_FASTQ=$scratchFolder/${outfiles[1]} \
		   1> $workFolder/$ID.out 2> $workFolder/$ID.err

# $java17 -Djava.io.tmpdir=$scratchFolder -Xmx4g -jar \
# 		   $picard/SamToFastq.jar \
# 		   INPUT=$PIPELINEHOMEFOLDER/$INPUTFOLDER/${infiles[0]} \
# 		   FASTQ=$scratchFolder/${outfiles[0]}  \
# 		   SECOND_END_FASTQ=$scratchFolder/${outfiles[1]} \
# 		   1> $workFolder/$ID.out 2> $workFolder/$ID.err
		   
		   # try to pipe output and error to file and then check for errors 
date
exceptCount=$(fgrep -c PicardException $workFolder/$ID.err )
if [ $exceptCount -gt 0 ]
then
	echo Error - exception in picard/SamToFastq.jar
	cat $workFolder/$ID.err
	ls -l $workFolder
	rm -r $scratchFolder
else
	ls -l $scratchFolder # just for debugging
	if [ ! -e $scratchFolder/${outfiles[0]} -o ! -e $scratchFolder/${outfiles[1]} ]
	then
		echo Error - $scratchFolder/${outfiles[0]} and $scratchFolder/${outfiles[1]} not written
		echo $workFolder/$ID.err:
		cat $workFolder/$ID.err
		error=yes
		# rm -r $scratchFolder
	else
		cd .. # because will rm $scratchFolder
		fastqSize1=$(stat -c%s $scratchFolder/${outfiles[0]})
		fastqSize2=$(stat -c%s $scratchFolder/${outfiles[1]})
		inSize=$(stat -c%s $PIPELINEHOMEFOLDER/$INPUTFOLDER/${infiles[0]})
		percent=$(echo "( $fastqSize1 + $fastqSize2 ) / $inSize * 100 " | bc )
		echo $inSize $fastqSize1  $fastqSize2 $percent
		if [ $fastqSize1 -neq \$fastqSize2 ]
		then
			echo Error - sizes of fastq files are not equal
			error=yes
		else
			mv $scratchFolder/${outfiles[0]} $PIPELINEHOMEFOLDER/$OUTPUTFOLDER/${outfiles[0]}
			mv $scratchFolder/${outfiles[1]} $PIPELINEHOMEFOLDER/$OUTPUTFOLDER/${outfiles[1]}
			# assumes they are on same file system so mv is instant - does not work if using scratch0
		fi
	fi
fi
done

OUTPUTFOLDER=$SAVEDOUTPUTFOLDER
outfiles=($OUTPUTFILES)
if [ error == no ]
then
# try merging the fastqs
	if [ ! -e $PIPELINEHOMEFOLDER/$INPUTFOLDER/${ID}_disc_sorted.bam ]
	then
		mv $PIPELINEHOMEFOLDER/unmergedFastq/${ID}_sorted_unique.r1.fastq $PIPELINEHOMEFOLDER/$OUTPUTFOLDER/${outfiles[0]}
		mv $PIPELINEHOMEFOLDER/unmergedFastq/${ID}_sorted_unique.r2.fastq $PIPELINEHOMEFOLDER/$OUTPUTFOLDER/${outfiles[1]}
	else
        mv $PIPELINEHOMEFOLDER/unmergedFastq/${ID}_sorted_unique.r1.fastq $scratchFolder/${outfiles[0]}
		cat $PIPELINEHOMEFOLDER/unmergedFastq/${ID}_disc_sorted.r1.fastq >> $scratchFolder/${outfiles[0]}
        mv $PIPELINEHOMEFOLDER/unmergedFastq/${ID}_sorted_unique.r2.fastq $scratchFolder/${outfiles[1]}
		cat $PIPELINEHOMEFOLDER/unmergedFastq/${ID}_disc_sorted.r2.fastq >> $scratchFolder/${outfiles[1]}
		fastqSize1=$(stat -c%s $scratchFolder/${outfiles[0]})
		fastqSize2=$(stat -c%s $scratchFolder/${outfiles[1]})
		if [ $fastqSize1 -neq \$fastqSize2 ]
		then
			echo Error - sizes of fastq files are not equal
			error=yes
		else
			mv $scratchFolder/${outfiles[0]} $PIPELINEHOMEFOLDER/$OUTPUTFOLDER/${outfiles[0]}
			mv $scratchFolder/${outfiles[1]} $PIPELINEHOMEFOLDER/$OUTPUTFOLDER/${outfiles[1]}
			# assumes they are on same file system so mv is instant - does not work if using scratch0
		fi
	 # need to merge then move
	fi
fi

if [ error == no ]
then
  cd ..
  rm -r $scratchFolder
fi
