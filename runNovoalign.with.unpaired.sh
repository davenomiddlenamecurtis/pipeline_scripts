# template for a script to be part of pipeline

# this script differs in that one of the input files, a fastq with unpaired reads, may or may not be present
# plan is to align these reads with standard commands, including samblaster which marks duplicates
# I assume samblaster will write no reads as being discordant because they are all single
# then align paired reads and merge unpaired reads with the "concordant" bam

# this was causing IO problems so I am going to move to do the main work on scratch0

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
# HVMEM=8G
# TMEM=8G
HVMEM=5G
TMEM=5G
# these were 3 G

# neeed more memory to run java
NCORES=6
# SCRATCH=100G was taking ages to queue
SCRATCH=15G 
# SCRATCH=10G was running out
# NHOURS=480
NHOURS=16
# NHOURS=40
# should be enough for an exome, we will see - there were two for which 16 was not enough


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
# I will change this
rm -fr $workFolder
mkdir $workFolder

scratchFolder=/scratch0/rejudcu/runNovoalignTemp/$ID
mkdir /scratch0/rejudcu
mkdir /scratch0/rejudcu/runNovoalignTemp
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
cd $scratchFolder
rm -f $scratchFolder/*
code=$ID
f1=${infiles[0]}
f2=${infiles[1]}
for f in $f1 $f2
do
  cp $PIPELINEHOMEFOLDER/$INPUTFOLDER/$f .
done
unpairedFastq=$ID.unpaired.fastq.gz
unpairedBam=$ID.unpaired.bam
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
OK=yes
# $novoalign -c ${ncores} -o SAM $'@RG\tID:${extraID}${code}\tSM:${extraID}${code}\tLB:${extraID}$code\tPL:ILLUMINA' --rOQ --hdrhd 3 -H -k -a -o Soft -t ${tparam} -F ${inputFormat} -f ${f1} ${f2}  -d ${novoalignRef} | ${samblaster} -e -d ${output}/${code}_disc.sam  | ${samtools} view -Sb - > ${output}/${code}.bam
# above does not expand correctly the way I am writing scripts, should be:

if [ -e $unpairedFastq ]
then
	rm -f $PIPELINEHOMEFOLDER/$TEMPFOLDER/$ID/$unpairedBam
	$novoalign -c ${ncores} -o SAM \$"@RG\\tID:${code}\\tSM:${code}\\tLB:$code\\tPL:ILLUMINA" --rOQ --hdrhd 3 -H -k -a -o Soft -t ${tparam} -F ${inputFormat} -f $unpairedFastq  -d ${novoalignRef} 2> novoalign.err | ${samblaster} -e -d ${outfiles[1]} 2> samblaster.err | ${samtools} view -Sb -o $unpairedBam - 2> samtools.err
	date
	cp *.err $workFolder
	countDone=\$(fgrep -c Done novoalign.err)
	if [ \$countDone -eq 0 -o -e ${outfiles[1]} -o ! -e $PIPELINEHOMEFOLDER/$TEMPFOLDER/$ID/$unpairedBam ]
	then
		echo Problem running $novoalign on $unpairedFastq, log file did not include \"Done\" or a discordant bam was output or no bam output
		echo $workFolder/novoalign.err:
		cat $workFolder/novoalign.err
		echo end of $workFolder/novoalign.err
		echo $workFolder/samblaster.err:
		cat $workFolder/samblaster.err
		echo end of $workFolder/samblaster.err
		echo ls -l $workFolder
		ls -l $workFolder
		echo ls -l $scratchFolder
		ls -l $scratchFolder
		echo df -h
		df -h
		OK=no
	else
		cp $unpairedBam $workFolder/$unpairedBam
	fi
fi

if [ \$OK = yes ]
then
	pwd
	ls -lh
	date
	$novoalign -c ${ncores} -o SAM \$"@RG\\tID:${code}\\tSM:${code}\\tLB:$code\\tPL:ILLUMINA" --rOQ --hdrhd 3 -H -k -a -o Soft -t ${tparam} -F ${inputFormat} -f ${f1} ${f2}  -d ${novoalignRef} 2> novoalign.err | ${samblaster} -e -d ${outfiles[1]} 2> samblaster.err | ${samtools} view -Sb -o ${outfiles[0]} - 2> samtools.err
	date
	cp *.err $workFolder
	countDone=\$(fgrep -c Done $workFolder/novoalign.err)
	if [ \$countDone -eq 0 ]
	then
		echo Problem running $novoalign, log file did not include \"Done\"
		echo $workFolder/novoalign.err:
		cat $workFolder/novoalign.err
		echo end of $workFolder/novoalign.err
		echo $workFolder/samblaster.err:
		cat $workFolder/samblaster.err
		echo end of $workFolder/samblaster.err
		echo ls -l $workFolder
		ls -l $workFolder
		echo ls -l $scratchFolder
		ls -l $scratchFolder
		echo df
		df
		OK=no
	else
		cp $OUTPUTFILES $workFolder
	fi
fi
if [ ! -e $workFolder/${outfiles[0]} -o ! -s $workFolder/${outfiles[0]} ]
then
	echo Error: $workFolder/${outfiles[0]} was not written correctly
	ls -l $workFolder
	ls -l $scratchFolder
	OK=no
fi
if [ ! -e $workFolder/${outfiles[1]} -o ! -s $workFolder/${outfiles[1]} ]
then
	echo Error: $workFolder/${outfiles[1]} was not written correctly
	ls -l $workFolder
	ls -l $scratchFolder
	OK=no
fi
if [ \$OK = yes ]
then
	countMarked=\$(fgrep -c Marked $workFolder/samblaster.err)
	if [ \$countMarked -eq 0 ]
	then
		echo Problem running $samblaster, log file did not include \"Marked\"
		cat $workFolder/samblaster.err
		ls -l $workFolder
		OK=no
	fi
fi

if [ \$OK = yes -a -e $workFolder/$unpairedBam ]
then
	rm -f tomerge.bam
	mv ${outfiles[0]} tomerge.bam
	$java17 -Djava.io.tmpdir=$scratchFolder -Xmx4g -jar \
		$picard/MergeSamFiles \
		INPUT=tomerge.bam \
		INPUT=$unpairedBam \
		OUTPUT=$workFolder/${outfiles[0]}
	cp ${outfiles[0]} $workFolder/${outfiles[0]}
# may need to introduce some error checking here
fi

if [ \$OK = yes ]
then
	mv $workFolder/${outfiles[0]} $PIPELINEHOMEFOLDER/$OUTPUTFOLDER/${outfiles[0]}
	mv $workFolder/${outfiles[1]} $PIPELINEHOMEFOLDER/$OUTPUTFOLDER/${outfiles[1]}
	echo $novoalign completed OK
else
	echo Error: problem running novoalign and samblaster - output files not written
fi
rm -rf $scratchFolder
date
