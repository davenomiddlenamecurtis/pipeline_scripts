# template for a script to be part of pipeline

# TEMPFOLDER is the place for intermediate files belonging to the script in main project space
# except for SCRATCHFOLDER all folders will be relative to PIPELINEHOMEFOLDER
TEMPFOLDER=genotypeGvcfstemp

# INPUTFOLDER is folder where to find input files, relative to $PIPELINEHOMEFOLDERn
INPUTFOLDER=combinedGVCF

# INPUTFILES is spec of input files in $PIPELINEHOMEFOLDER/$INPUTFOLDER (can have wildcards, usually will have $ID in it)
INPUTFILES="$ID.lst $ID.chr"

# OUTPUTFOLDER is folder where to find output files, relative to $PIPELINEHOMEFOLDER
OUTPUTFOLDER=vcf

# OUTPUTFILES is list of output files in $PIPELINEHOMEFOLDER/$OUTPUTFOLDER (usually will have $ID in it)
OUTPUTFILES="$ID.vcf.gz $ID.vcf.gz.tbi"

#WRITTENFILES is a list of files which will be created by this script
WRITTENFILES="$ID.vcf.gz $ID.vcf.gz.tbi"

# HVMEM will be read and used to request hvmem for the script
HVMEM=8G
TMEM=8G

# need more memory to run java

NCORES=6
SCRATCH=1G
NHOURS=72


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

# variables for alignment:
memory2=7
ncores=$NCORES
extraID=$ID
tparam=250

# this is mine:
javaTemp=/scratch0/genotypeGVCFs$ID
mkdir $javaTemp

# now the ID will be for a group of combined gVCFs, listed in the input file
code=$ID
outputFolder=$PIPELINEHOMEFOLDER/$OUTPUTFOLDER
tempFolder=$workFolder

rm $workFolder/*

date
cd $workFolder

tempScript=$ID.tempScript.sh

# lines below will be read and then written to script file with: echo "$line" >> $scriptname

chr=`cat $PIPELINEHOMEFOLDER/$INPUTFOLDER/${infiles[1]}`

echo #!/bin/bash > $tempScript 
echo $java -Xmx6g -jar $GATK \\\\>> $tempScript
echo -R $fasta  \\\\>> $tempScript
echo -T GenotypeGVCFs  \\\\>> $tempScript 
echo -L \$chr  \\\\>> $tempScript 
echo               --interval_padding 100 \\\\>> $tempScript 
echo               --annotation InbreedingCoeff \\\\>> $tempScript 
echo               --annotation QualByDepth \\\\>> $tempScript 
echo               --annotation HaplotypeScore \\\\>> $tempScript 
echo               --annotation MappingQualityRankSumTest \\\\>> $tempScript 
echo               --annotation ReadPosRankSumTest \\\\>> $tempScript 
echo               --annotation FisherStrand \\\\>> $tempScript 

# did also have     -L ${chrPrefix}${chrCleanCode} \\
cat $PIPELINEHOMEFOLDER/$INPUTFOLDER/${infiles[0]} | while read gVCF
do
	echo --variant $gVCF \\\\>> $tempScript 
done
echo -o $tempFolder/${outfiles[0]} >> $tempScript 

bash $tempScript

tabix -f -p vcf $tempFolder/${outfiles[0]}

ls -l

# checks here

for f in $outfiles
do
	mv $tempFolder/\$f $outputFolder/\$f
done

# mv $tempFolder/$OUTPUTFILES $OUTPUTFOLDER/$OUTPUTFILES
# mv $tempFolder/${OUTPUTFILES}'*' $PIPELINEHOMEFOLDER/$OUTPUTFOLDER/$OUTPUTFILES

cd .. 
# rm -r $workFolder
rm -r $javaTemp

date
		