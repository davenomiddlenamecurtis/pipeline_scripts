# template for a script to be part of pipeline

# TEMPFOLDER is the place for intermediate files belonging to the script in main project space
# except for SCRATCHFOLDER all folders will be relative to PIPELINEHOMEFOLDER
TEMPFOLDER fastq2bamtemp

# INPUTFOLDER is folder where to find input files, relative to $PIPELINEHOMEFOLDERn
INPUTFOLDER fastq

# INPUTFILES is spec of input files in $PIPELINEHOMEFOLDER/$INPUTFOLDER (can have wildcards, usually will have $ID in it)
INPUTFILES ${ID}_sorted_unique.cleaned.r1.fastq.gz ${ID}_sorted_unique.cleaned.r2.fastq.gz

# OUTPUTFOLDER is folder where to find output files, relative to $PIPELINEHOMEFOLDER
OUTPUTFOLDER sam

# OUTPUTFILES is list of output files in $PIPELINEHOMEFOLDER/$OUTPUTFOLDER (usually will have $ID in it)
# these are all the files which should exist by the time this stage of the pipeline is complete
OUTPUTFILES ${ID}_aligned.sam

# WRITTENFILES is a list of output files $PIPELINEHOMEFOLDER/$OUTPUTFOLDER actually written by this script
# if one is missing or zero length all will be deleted before the script runs
WRITTENFILES ${ID}_aligned.sam

# HVMEM will be read and used to request hvmem for the script
HVMEM 8G
TMEM 8G
# these were 3 G

# neeed more memory to run java
NCORES 6
SCRATCH 1G
NHOURS 240


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

software=/cluster/project8/vyp/vincent/Software
java17=/share/apps/jdk1.7.0_45/jre/bin/java
java=/share/apps/jdk1.7.0_45/jre/bin/java
bundle=/scratch2/vyp-scratch2/GATK_bundle
GATK=${software}/GenomeAnalysisTK-3.3-0/GenomeAnalysisTK.jar
novoalign=${software}/novocraft3/novoalign
novosort=${software}/novocraft3/novosort
samblaster=${software}/samblaster/samblaster
samtools=${software}/samtools-1.1/samtools

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

# keep Vincent's naming convention where code refers to individual subject
code=$ID
f1=$PIPELINEHOMEFOLDER/$INPUTFOLDER/${infiles[0]}
f2=$PIPELINEHOMEFOLDER/$INPUTFOLDER/${infiles[1]}
output=$PIPELINEHOMEFOLDER/$OUTPUTFOLDER
tempFolder=$PIPELINEHOMEFOLDER/$TEMPFOLDER

rm $workFolder/*

# stuff for reference sequence
fasta=none
novoalignRef=none
if [[ "$reference" == "hg38_noAlt" ]]
then
    fasta=/scratch2/vyp-scratch2/reference_datasets/human_reference_sequence/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna
    novoalignRef=/scratch2/vyp-scratch2/reference_datasets/human_reference_sequence/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.k15.s2.novoindex
    chrPrefix='chr'
elif [[ "$reference" == "1kg" ]]
then
    fasta=/scratch2/vyp-scratch2/reference_datasets/human_reference_sequence/human_g1k_v37.fasta
    novoalignRef=/scratch2/vyp-scratch2/reference_datasets/human_reference_sequence/human_g1k_v37.fasta.k15.s2.novoindex
    chrPrefix=''
elif [[ "$reference" == "hg19" ]]
then
    fasta=/scratch2/vyp-scratch2/reference_datasets/human_reference_sequence/hg19_UCSC.fa
    novoalignRef=none
    chrPrefix='chr'
else
    stop Unsupported reference $reference
fi
for file in $fasta
do
    ls -lh $file
    if [ ! -e "$file"  ] && [ "$file" != "none" ]
    then 
        stop "Error, reference file $file does not exist"
    fi
done
for file in $novoalignRef
do
    ls -lh $file
    if [ ! -e "$file"  ] && [ "$file" != "none" ]
    then 
        stop "Error, reference file $file does not exist"
    fi
done
   

date
mkdir $PIPELINEHOMEFOLDER/$TEMPFOLDER/$ID/
# $novoalign -c ${ncores} -o SAM $'@RG\tID:${extraID}${code}\tSM:${extraID}${code}\tLB:${extraID}$code\tPL:ILLUMINA' --rOQ --hdrhd 3 -H -k -a -o Soft -t ${tparam} -F ${inputFormat} -f ${f1} ${f2}  -d ${novoalignRef} | ${samblaster} -e -d ${output}/${code}_disc.sam  | ${samtools} view -Sb - > ${output}/${code}.bam
# above does not expand correctly the way I am writing scripts, should be:
$novoalign -c ${ncores} -o SAM \$"@RG\\tID:${code}\\tSM:${code}\\tLB:$code\\tPL:ILLUMINA" --rOQ --hdrhd 3 -H -k -a -o Soft -t ${tparam} -F ${inputFormat} -f ${f1} ${f2}  -d ${novoalignRef} > $PIPELINEHOMEFOLDER/$TEMPFOLDER/$ID/${outfiles[0]} 2> $PIPELINEHOMEFOLDER/$TEMPFOLDER/$ID/novoalign.err
countDone=\$(fgrep -c Done $PIPELINEHOMEFOLDER/$TEMPFOLDER/$ID/novoalign.err)
if [ \$countDone -gt 0 ]
then
	mv $PIPELINEHOMEFOLDER/$TEMPFOLDER/$ID/${outfiles[0]} $PIPELINEHOMEFOLDER/$OUTPUTFOLDER/${outfiles[0]}
	echo $novoalign completed OK
else
	echo Problem running $novoalign, log file did not include \"Done\"
fi
date
