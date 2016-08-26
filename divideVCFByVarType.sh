# template for a script to be part of pipeline

# TEMPFOLDER is the place for intermediate files belonging to the script in main project space
# except for SCRATCHFOLDER all folders will be relative to PIPELINEHOMEFOLDER
TEMPFOLDER=divideVCFtemp

# INPUTFOLDER is folder where to find input files, relative to $PIPELINEHOMEFOLDERn
INPUTFOLDER=vcf

# INPUTFILES is spec of input files in $PIPELINEHOMEFOLDER/$INPUTFOLDER (can have wildcards, usually will have $ID in it)
# e.g. SSSDNM.22
INPUTFILES="$ID.vcf.gz $ID.vcf.gz.tbi"

# OUTPUTFOLDER is folder where to find output files, relative to $PIPELINEHOMEFOLDER
OUTPUTFOLDER=filteringVCF

# OUTPUTFILES is list of output files in $PIPELINEHOMEFOLDER/$OUTPUTFOLDER (usually will have $ID in it)
OUTPUTFILES="$ID.SNPs.vcf.gz $ID.SNPs.vcf.gz.tbi $ID.indels.vcf.gz $ID.indels.vcf.gz.tbi "
WRITTENFILES="$ID.SNPs.vcf.gz $ID.SNPs.vcf.gz.tbi $ID.indels.vcf.gz $ID.indels.vcf.gz.tbi "

# HVMEM will be read and used to request hvmem for the script
HVMEM=10G
TMEM=10G

# need more memory to run java

# NCORES=6
# NHOURS=24


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

# everything else is set in alignParsFile.txt

scratchFolder=$PIPELINEHOMEFOLDER/$TEMPFOLDER/$ID
mkdir $scratchFolder
workFolder=$scratchFolder

infiles=($INPUTFILES)
outfiles=($OUTPUTFILES)

javaTemp=/scratch0/divideVCF$ID
mkdir $javaTemp

output=$PIPELINEHOMEFOLDER/$OUTPUTFOLDER
tempFolder=$PIPELINEHOMEFOLDER/$TEMPFOLDER

rm $workFolder/*

date
cd $workFolder
errFile=$ID.err

$java -Djava.io.tmpdir=${javaTemp} -Xmx8g  -Xms8g  -jar $GATK -R $fasta \
	-T SelectVariants \
	-V $PIPELINEHOMEFOLDER/$INPUTFOLDER/${infiles[0]} \
	-selectType SNP \
	-o ${outfiles[0]} &> $errFile
	
cat $errFile
errorCount=$(fgrep -c ERROR $errFile)
if [ \$errorCount .gt 0 ]
then
	echo Found ERROR in $errFile
else
	tabix -p vcf ${outfiles[0]}
	
	$java -Djava.io.tmpdir=${javaTemp} -Xmx8g  -Xms8g  -jar $GATK -R $fasta \
		-T SelectVariants \
		-V $PIPELINEHOMEFOLDER/$INPUTFOLDER/${infiles[0]} \
		-selectType INDEL \
		-selectType MIXED \
		-o ${outfiles[2]} &> $errFile
	
	cat $errFile
	errorCount=$(fgrep -c ERROR $errFile)
	if [ \$errorCount .gt 0 ]
	then
		echo Found ERROR in $errFile
	else
		tabix -p vcf ${outfiles[2]}
		for (( i=0; i<4; ++i ))
		do 
			mv ${outfilesoutfiles[\$i]} $PIPELINEHOMEFOLDER/$OUTPUTFOLDER/${outfiles[\$i]} 
		done
	fi
fi

rm -r $javaTemp

date
		