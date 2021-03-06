# template for a script to be part of pipeline

# TEMPFOLDER is the place for intermediate files belonging to the script in main project space
# except for SCRATCHFOLDER all folders will be relative to PIPELINEHOMEFOLDER
TEMPFOLDER=fastq2bamtemp

# INPUTFOLDER is folder where to find input files, relative to $PIPELINEHOMEFOLDERn
INPUTFOLDER=fastq

# INPUTFILES is spec of input files in $PIPELINEHOMEFOLDER/$INPUTFOLDER (can have wildcards, usually will have $ID in it)
INPUTFILES="${ID}.r1.fastq.gz ${ID}.r2.fastq.gz"

# OUTPUTFOLDER is folder where to find output files, relative to $PIPELINEHOMEFOLDER
OUTPUTFOLDER=sam

# OUTPUTFILES is list of output files in $PIPELINEHOMEFOLDER/$OUTPUTFOLDER (usually will have $ID in it)
# these are all the files which should exist by the time this stage of the pipeline is complete
OUTPUTFILES="${ID}_conc.bam ${ID}_disc.sam"

# WRITTENFILES is a list of output files $PIPELINEHOMEFOLDER/$OUTPUTFOLDER actually written by this script
# if one is missing or zero length all will be deleted before the script runs
WRITTENFILES="${ID}_conc.bam ${ID}_disc.sam"

# HVMEM will be read and used to request hvmem for the script
HVMEM=8G
TMEM=8G
# these were 3 G

# neeed more memory to run java
NCORES=6
SCRATCH=10G
NHOURS=480


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

workFolder=$PIPELINEHOMEFOLDER/$TEMPFOLDER/$ID
# this needs to be on same system as OUTPUTFOLDER so can do fast mv
scratchFolder=/scratch0/runNovoalignTemp/$ID
mkdir /scratch0/runNovoalignTemp
mkdir $scratchFolder

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
#     fasta=/scratch2/vyp-scratch2/reference_datasets/human_reference_sequence/human_g1k_v37.fasta
#     novoalignRef=/scratch2/vyp-scratch2/reference_datasets/human_reference_sequence/human_g1k_v37.fasta.k15.s2.novoindex
    fasta=$PROJECTDIR/reference1g/human_g1k_v37.fasta
    novoalignRef=$PROJECTDIR/reference1g/human_g1k_v37.fasta.k15.s2.novoindex
    chrPrefix=''
elif [[ "$reference" == "hg19" ]]
then
    fasta=/scratch2/vyp-scratch2/reference_datasets/human_reference_sequence/hg19_UCSC.fa
    novoalignRef=none
    chrPrefix='chr'
else
    stop Unsupported reference $reference
fi
for file in $fasta $novoalignRef
do
    ls -lh $file
    if [ ! -e "$file"  ] && [ "$file" != "none" ]
    then 
        stop "Error, reference file $file does not exist"
	else
		cp $file $scratchFolder
    fi
done

fasta=$scratchFolder/${fasta##*/}
novoalignRef=$scratchFolder/${novoalignRef##*/}

date
mkdir $PIPELINEHOMEFOLDER/$TEMPFOLDER/$ID/
# $novoalign -c ${ncores} -o SAM $'@RG\tID:${extraID}${code}\tSM:${extraID}${code}\tLB:${extraID}$code\tPL:ILLUMINA' --rOQ --hdrhd 3 -H -k -a -o Soft -t ${tparam} -F ${inputFormat} -f ${f1} ${f2}  -d ${novoalignRef} | ${samblaster} -e -d ${output}/${code}_disc.sam  | ${samtools} view -Sb - > ${output}/${code}.bam
# above does not expand correctly the way I am writing scripts, should be:
$novoalign -c ${ncores} -o SAM \$"@RG\\tID:${code}\\tSM:${code}\\tLB:$code\\tPL:ILLUMINA" --rOQ --hdrhd 3 -H -k -a -o Soft -t ${tparam} -F ${inputFormat} -f ${f1} ${f2}  -d ${novoalignRef} 2> $PIPELINEHOMEFOLDER/$TEMPFOLDER/$ID/novoalign.err | ${samblaster} -e -d $PIPELINEHOMEFOLDER/$TEMPFOLDER/$ID/${outfiles[1]} 2> $PIPELINEHOMEFOLDER/$TEMPFOLDER/$ID/samblaster.err | ${samtools} view -Sb -o $PIPELINEHOMEFOLDER/$TEMPFOLDER/$ID/${outfiles[0]} - 2> $PIPELINEHOMEFOLDER/$TEMPFOLDER/$ID/samtools.err
date
OK=yes
countDone=\$(fgrep -c Done $PIPELINEHOMEFOLDER/$TEMPFOLDER/$ID/novoalign.err)
if [ \$countDone -eq 0 ]
then
	echo Problem running $novoalign, log file did not include \"Done\"
	echo $PIPELINEHOMEFOLDER/$TEMPFOLDER/$ID/novoalign.err:
	cat $PIPELINEHOMEFOLDER/$TEMPFOLDER/$ID/novoalign.err
	echo end of $PIPELINEHOMEFOLDER/$TEMPFOLDER/$ID/novoalign.err
	echo $PIPELINEHOMEFOLDER/$TEMPFOLDER/$ID/samblaster.err:
	cat $PIPELINEHOMEFOLDER/$TEMPFOLDER/$ID/samblaster.err
	echo end of $PIPELINEHOMEFOLDER/$TEMPFOLDER/$ID/samblaster.err
	echo ls -l $PIPELINEHOMEFOLDER/$TEMPFOLDER/$ID
	ls -l $PIPELINEHOMEFOLDER/$TEMPFOLDER/$ID
	echo ls -l $scratchFolder
	ls -l $scratchFolder
	echo df
	df
	OK=no
fi
if [ ! -e $PIPELINEHOMEFOLDER/$TEMPFOLDER/$ID/${outfiles[0]} -o ! -s $PIPELINEHOMEFOLDER/$TEMPFOLDER/$ID/${outfiles[0]} ]
then
	echo Error: $PIPELINEHOMEFOLDER/$TEMPFOLDER/$ID/${outfiles[0]} was not written correctly
	ls -l $PIPELINEHOMEFOLDER/$TEMPFOLDER/$ID
	ls -l $scratchFolder
	OK=no
fi
if [ \$OK = yes ]
then
	countMarked=\$(fgrep -c Marked $PIPELINEHOMEFOLDER/$TEMPFOLDER/$ID/samblaster.err)
	if [ \$countMarked -eq 0 ]
	then
		echo Problem running $samblaster, log file did not include \"Marked\"
		cat $PIPELINEHOMEFOLDER/$TEMPFOLDER/$ID/samblaster.err
		ls -l $PIPELINEHOMEFOLDER/$TEMPFOLDER/$ID
		OK=no
	fi
fi

if [ \$OK = yes ]
then
	mv $PIPELINEHOMEFOLDER/$TEMPFOLDER/$ID/${outfiles[0]} $PIPELINEHOMEFOLDER/$OUTPUTFOLDER/${outfiles[0]}
	mv $PIPELINEHOMEFOLDER/$TEMPFOLDER/$ID/${outfiles[1]} $PIPELINEHOMEFOLDER/$OUTPUTFOLDER/${outfiles[1]}
	echo $novoalign completed OK
else
	echo Error: problem running novoalign and samblaster - output files not written
fi
rm -rf $scratchFolder
date
