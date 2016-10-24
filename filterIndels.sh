# template for a script to be part of pipeline

# TEMPFOLDER is the place for intermediate files belonging to the script in main project space
# except for SCRATCHFOLDER all folders will be relative to PIPELINEHOMEFOLDER
TEMPFOLDER=filterindeltemp

# INPUTFOLDER is folder where to find input files, relative to $PIPELINEHOMEFOLDERn
INPUTFOLDER=filteringVCF

# INPUTFILES is spec of input files in $PIPELINEHOMEFOLDER/$INPUTFOLDER (can have wildcards, usually will have $ID in it)
# e.g. SSSDNM.22
INPUTFILES="$ID.indels.vcf.gz $ID.indels.vcf.gz.tbi $ID.SNPs.filtered.vcf.gz $ID.SNPs.filtered.vcf.gz.tbi $ID.SNPs.recal.plots.R"
# list filtered SNPs as input even though not actually needed to ensure filterSNPs.sh is run if necessary

# OUTPUTFOLDER is folder where to find output files, relative to $PIPELINEHOMEFOLDER
OUTPUTFOLDER=filteringVCF

# OUTPUTFILES is list of output files in $PIPELINEHOMEFOLDER/$OUTPUTFOLDER (usually will have $ID in it)
OUTPUTFILES="$ID.indels.filtered.vcf.gz $ID.indels.filtered.vcf.gz.tbi $ID.SNPs.filtered.vcf.gz $ID.SNPs.filtered.vcf.gz.tbi $ID.SNPs.recal.plots.R"
WRITTENFILES="$ID.indels.filtered.vcf.gz $ID.indels.filtered.vcf.gz.tbi "

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

numBad=1000
maxGauss=6
# everything else is set in alignParsFile.txt

scratchFolder=$PIPELINEHOMEFOLDER/$TEMPFOLDER/$ID
mkdir $scratchFolder
workFolder=$scratchFolder

infiles=($INPUTFILES)
outfiles=($OUTPUTFILES)

javaTemp=/scratch0/filterSNPs$ID
mkdir $javaTemp

output=$PIPELINEHOMEFOLDER/$OUTPUTFOLDER
tempFolder=$PIPELINEHOMEFOLDER/$TEMPFOLDER

rm $workFolder/*

date
cd $workFolder
errFile=$ID.err

$java -Djava.io.tmpdir=${javaTemp} -Xmx4g  -Xms4g  -jar ${GATK} \
    -T VariantFiltration \
    -R $fasta \
    -V $PIPELINEHOMEFOLDER/$INPUTFOLDER/${infiles[0]} \
    --filterExpression \"QD < 2.0 || FS > 50.0 || ReadPosRankSum < -20.0\" \
    --filterName \"FAIL\" \
    -o ${outfiles[0]} &> $errFile
ls -l 
cat $errFile
errorCount=$(fgrep -ic ERROR $errFile)
if [ \$errorCount -gt 0 ]
then
	echo Found ERROR in $errFile
else
	tabix ${outfiles[0]}
	for (( i=0; i<2; ++i ))
	do 
		mv ${outfiles[\$i]} $PIPELINEHOMEFOLDER/$OUTPUTFOLDER/${outfiles[\$i]} 
	done
	fi
fi

rm -r $javaTemp

date
		