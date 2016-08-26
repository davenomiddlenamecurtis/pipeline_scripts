# template for a script to be part of pipeline

# TEMPFOLDER is the place for intermediate files belonging to the script in main project space
# except for SCRATCHFOLDER all folders will be relative to PIPELINEHOMEFOLDER
TEMPFOLDER=filterSNPtemp

# INPUTFOLDER is folder where to find input files, relative to $PIPELINEHOMEFOLDERn
INPUTFOLDER=filteringVCF

# INPUTFILES is spec of input files in $PIPELINEHOMEFOLDER/$INPUTFOLDER (can have wildcards, usually will have $ID in it)
# e.g. SSSDNM.22
INPUTFILES="$ID.SNPs.vcf.gz $ID.SNPs.vcf.gz.tbi "

# OUTPUTFOLDER is folder where to find output files, relative to $PIPELINEHOMEFOLDER
OUTPUTFOLDER=filteringVCF

# OUTPUTFILES is list of output files in $PIPELINEHOMEFOLDER/$OUTPUTFOLDER (usually will have $ID in it)
OUTPUTFILES="$ID.SNPs.filtered.vcf.gz $ID.SNPs.filtered.vcf.gz.tbi $ID.SNPs.combrec.recal $ID.SNPs.combtranch $ID.SNPs.recal.plots.R"
WRITTENFILES="$ID.SNPs.filtered.vcf.gz $ID.SNPs.filtered.vcf.gz.tbi $ID.SNPs.combrec.recal $ID.SNPs.combtranch $ID.SNPs.recal.plots.R"

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

$java -Djava.io.tmpdir=${javaTemp} -Xmx8g  -Xms8g  -jar $GATK -R $fasta \
	-T VariantRecalibrator \
	-input ${infiles[0]}
	--maxGaussians $maxGauss --mode SNP \
	-resource:hapmap,VCF,known=false,training=true,truth=true,prior=15.0 ${bundle}/hapmap_3.3.b37.vcf  \
	-resource:omni,VCF,known=false,training=true,truth=false,prior=12.0 ${bundle}/1000G_omni2.5.b37.vcf \
	-resource:dbsnp,VCF,known=true,training=false,truth=false,prior=8.0 ${bundle}/dbsnp_137.b37.vcf \
	-an QD -an FS -an ReadPosRankSum -an InbreedingCoeff \
	-tranche 100.0 -tranche 99.9 -tranche 99.8 -tranche 99.6 -tranche 99.5 -tranche 99.4 -tranche 99.3 -tranche 99.0 -tranche 98.0 -tranche 97.0 -tranche 90.0 \
	--minNumBadVariants ${numBad} \
	-recalFile ${outfiles[2]} \
	-tranchesFile ${outfiles[3]} \
	-rscriptFile  ${outfiles[4]}  &> $errFile
# might lose minNumBadVariants

cat $errFile
errorCount=$(fgrep -c ERROR $errFile)
if [ \$errorCount .gt 0 ]
then
	echo Found ERROR in $errFile
else
	${Rscript} ${outfiles[4]}
	$java -Xmx8g  -Xms8g  -jar ${GATK} -T ApplyRecalibration -R $fasta \
		-input ${infiles[0]}
       -o ${outfiles[0]} \
       --ts_filter_level 99.5 \
		-recalFile ${outfiles[2]} \
		-tranchesFile ${outfiles[3]} \
       --mode SNP &> $errFile

	cat $errFile
	errorCount=$(fgrep -c ERROR $errFile)
	if [ \$errorCount .gt 0 ]
	then
		echo Found ERROR in $errFile
	else
		tabix ${outfiles[0]}
		cp *.pdf $PIPELINEHOMEFOLDER/$OUTPUTFOLDER # not sure whether or not this will work
		for (( i=0; i<5; ++i ))
		do 
			mv ${OUTPUTFILES[\$i]} $PIPELINEHOMEFOLDER/$OUTPUTFOLDER/${OUTPUTFILES[\$i]} 
		done
	fi
fi

rm -r $javaTemp

date
		