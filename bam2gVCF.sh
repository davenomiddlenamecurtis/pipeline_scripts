# template for a script to be part of pipeline

# TEMPFOLDER is the place for intermediate files belonging to the script in main project space
# except for SCRATCHFOLDER all folders will be relative to PIPELINEHOMEFOLDER
TEMPFOLDER=bam2gVCFtemp

# INPUTFOLDER is folder where to find input files, relative to $PIPELINEHOMEFOLDERn
INPUTFOLDER=bam

# INPUTFILES is spec of input files in $PIPELINEHOMEFOLDER/$INPUTFOLDER (can have wildcards, usually will have $ID in it)
INPUTFILES=${ID}_sorted_unique.bam

# OUTPUTFOLDER is folder where to find output files, relative to $PIPELINEHOMEFOLDER
OUTPUTFOLDER=gVCF

# OUTPUTFILES is list of output files in $PIPELINEHOMEFOLDER/$OUTPUTFOLDER (usually will have $ID in it)
OUTPUTFILES="${ID}.gvcf.gz ${ID}.gvcf.gz.tbi"

# HVMEM will be read and used to request hvmem for the script
HVMEM=8G
TMEM=8G

# need more memory to run java

NCORES=6
SCRATCH=1G
NHOURS=24


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

target=/cluster/project8/vyp/exome_sequencing_multisamples/target_region/data/merged_exome_target_bed
# only for exomes!!!

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
# it looks like when I added read groups I used SM=$code, which should set the group name to the ID
tparam=250
inputFormat=STDFQ
reference=1kg

# this is mine:
javaTemp=/scratch0/bam2gVCF$ID
mkdir $javaTemp

# keep Vincent's naming convention where code refers to individual subject
code=$ID
f1=$PIPELINEHOMEFOLDER/$INPUTFOLDER/${infiles[0]}
output=$PIPELINEHOMEFOLDER/$OUTPUTFOLDER
tempFolder=$PIPELINEHOMEFOLDER/$TEMPFOLDER

rm $workFolder/*

date
cd $workFolder

# edited parameters to match those in WGS/WGS_pipeline.sh on 25/8/16
$java -Djava.io.tmpdir=${javaTemp} -Xmx8g  -Xms8g  -jar $GATK -T HaplotypeCaller -R $fasta -I $PIPELINEHOMEFOLDER/$INPUTFOLDER/${infiles[0]} \
	--dbsnp ${bundle}/dbsnp_137.b37.vcf \
	--emitRefConfidence GVCF \
	-rf NotPrimaryAlignment \
	-stand_call_conf 30.0 \
	-stand_emit_conf 10.0 \
	--GVCFGQBands 10 --GVCFGQBands 20 --GVCFGQBands 60 \
	-L $target \
	-variant_index_type LINEAR -variant_index_parameter 128000 \
	-o ${ID}.gvcf &> ${outfiles[0]}.out
cat ${outfiles[0]}.out
errorCount=$(fgrep -c ERROR ${outfiles[0]}.out)
if [ \$errorCount -gt 0 ]
then
	echo Found ERROR in ${outfiles[0]}.out
else
	bgzip ${ID}.gvcf # should make ${ID}.gvcf.gz, which is ${outfiles[0]}
	tabix -p vcf ${outfiles[0]}
	mv ${outfiles[0]} $PIPELINEHOMEFOLDER/$OUTPUTFOLDER/${outfiles[0]} 
	mv ${outfiles[1]} $PIPELINEHOMEFOLDER/$OUTPUTFOLDER/${outfiles[1]} 

fi

rm -r $javaTemp

date
		