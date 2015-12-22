#!/bin/bash

# script to build and submit pipeline scripts
# edited on githubs server
# Usage:
# Need to set these environment variables:
# PIPELINENAME - name of pipeline
# PIPELINESCRIPTSFOLDER - folder for the scripts below
# PIPELINESCRIPTS - list of scripts in order to be applied to each ID
# IDFILE - full path of file containing IDs

# Following are optional:
# ATTEMPTS - number of times to loop round the pipeline
# PIPELINEHOMEFOLDER

# This is optional, but if it is set then it will be copied into each script and used to set variables
# PIPELINEPARSFILE

DEFAULTHVMEM=1G
DEFAULTTMEM=1G
DEFAULTNCORES=1
DEFAULTSCRATCH=1G
DEFAULTNHOURS=3
DEFAULTATTEMPTS=1
DELETEINTERMEDIATES=no 

# Notes
# When I had no argument for exit, it would write ESC[H ESC[2J to stdout, which would clear the screen and would confuse cat (clears screen?) but would be invisible in more and the editor 	
# On new cluster other script would exit as soon as one analysis done. I suspect this is because errexit is set (set -e, set -o errexit), so I am inserting set +e to switch it off

NVARIABLESFORSCRIPTS=0
if [ ! -z "$PIPELINEPARSFILE" ]
then
source $PIPELINEPARSFILE
fi

if [ -z "PIPELINENAME" -o -z "$PIPELINESCRIPTSFOLDER" -o -z "$PIPELINESCRIPTS" -o -z "$IDFILE" ]
then
echo Usage:
echo Need to set these environment variables:
echo PIPELINENAME - name of pipeline
echo PIPELINESCRIPTSFOLDER - folder for the scripts below
echo PIPELINESCRIPTS - list of scripts in order to be applied to each ID
echo IDFILE - full path of file containing IDs
fi

if [ -z "$PIPELINEHOMEFOLDER" ]
then
	PIPELINEHOMEFOLDER=/cluster/project8/bipolargenomes/
fi
if [ -z "$ATTEMPTS" ]
then
	ATTEMPTS=$DEFAULTATTEMPTS
fi
if [ -z "$PIPELINETEMPFOLDER" ]
then
	PIPELINETEMPFOLDER=$PIPELINEHOMEFOLDER/pipelinetempfolder
fi
DEFAULTTEMPFOLDER=$PIPELINETEMPFOLDER
mkdir $PIPELINETEMPFOLDER

for p in PIPELINENAME PIPELINESCRIPTSFOLDER PIPELINESCRIPTS IDFILE PIPELINEHOMEFOLDER ATTEMPTS PIPELINETEMPFOLDER
do
	if [ ! -z "${!p}" ] # indirect parameter expansion
	then
		VARIABLESFORSCRIPTS[NVARIABLESFORSCRIPTS]=$p
		NVARIABLESFORSCRIPTS=$((NVARIABLESFORSCRIPTS+1))
		# it doesn't matter if some of these are already there
	fi
done

i=0
for s in $PIPELINESCRIPTS; do SCRIPTARRAY[$i]=$s; i=$((i+1)); done
SCRIPTNUMBER=$i

cat $IDFILE | while read ID
do

# use qstat to see if scripts are running for this ID and if so skip it with a message

if [ $OLDCLUSTER = yes ]
then
	qcount=( $( qstat -j "*$ID*" | wc ) )
else
	qcount=( $( qstat -j "*$ID*" |& wc ) )
fi
if [ ${qcount[0]} -gt 2 ]
# if no jobs then two line error message, else many lines
then
	echo Skipping $ID because qstat says there are already jobs submitted for this ID
	continue
fi

# read through all the scripts, work out which are the expected input and output files
# set parameters for HMEM etc.
# make arrays matching the SCRIPTARRAY array
# when reading filenames, substitute $ID for the string \$ID
# slightly tricky because input and output file specs may be either "file*" or "file1 file2" or a mixture
# so have to cd to folder then expand

for (( i=0; i < $SCRIPTNUMBER; i++ ))
do
	tempVarFile=$PIPELINETEMPFOLDER/tempVarFile.sh
	if [ -e $tempVarFile ] ; then rm $tempVarFile ; fi
	s=${SCRIPTARRAY[$i]}
	for p in HVMEM TMEM NCORES SCRATCH NHOURS
	do 
		toset=$p[$i];
		default=DEFAULT$p;
		echo $toset=${!default} >> $tempVarFile
	done
	cat $PIPELINESCRIPTSFOLDER/$s | while read line
	do
		if [ "$line" = "" ]; then continue; fi
		if [ "${line%%#*}" = "" ] ; then continue; fi 
		
		first=${line%%=*}
		rest=${line#*=}
		if [ $first = COMMANDS ]; then break; fi
		
		toset=$first[$i]
		case $first in
		HVMEM | TMEM | NCORES | SCRATCH | NHOURS | SCRIPTFOLDER | INPUTFOLDER | OUTPUTFOLDER | TEMPFOLDER | INPUTFILES | OUTPUTFILES | WRITTENFILES)
			echo $toset=$rest  >> $tempVarFile
			;;
		* )
			echo Unrecognised line in $PIPELINESCRIPTSFOLDER/$s before COMMANDS section:
			echo $line
			exit
			break
			;;
		esac
	done
	source $tempVarFile
done

# work from the last script to find the latest one which has necessary input files
# then can note that all previous output files are intermediate and candidates for deletion
# write a delete intermediates script which can be run by the user if desired

SCRIPTSTORUNNUMBER=0
for (( i=$SCRIPTNUMBER-1;i>=0; i-- ))
do
	outfiles=${OUTPUTFILES[$i]}
	filemissing=no
	if [ ! -e $PIPELINEHOMEFOLDER/${OUTPUTFOLDER[$i]} ]
	then
		mkdir $PIPELINEHOMEFOLDER/${OUTPUTFOLDER[$i]}
	fi
	cd $PIPELINEHOMEFOLDER/${OUTPUTFOLDER[$i]}
	for f in $outfiles; do if [ ! -e $f -o ! -s $f ]; then filemissing=yes; fi; done
	if [ $filemissing = no ]
	then
		if [ ! $i -eq $((SCRIPTNUMBER - 1)) ]
		then
			echo Error trying to set up scripts for $ID because none of these output files were missing:
			echo ${OUTPUTFILES[$i]}
			echo But subsequent script thought it was missing input files
			break
		else
			echo All analyses complete for $ID
			SCRIPTSTORUNNUMBER=0
			break
		fi
	fi
	infiles=${INPUTFILES[$i]}
	filemissing=no
	if [ ! -e $PIPELINEHOMEFOLDER/${INPUTFOLDER[$i]} ]
	then
		mkdir $PIPELINEHOMEFOLDER/${INPUTFOLDER[$i]}
	fi
	# I'm not really sure if I should be making this folder if it doesn't exist
	cd $PIPELINEHOMEFOLDER/${INPUTFOLDER[$i]}
	for f in $infiles; do if [ ! -e $f -o ! -s $f ]; then filemissing=yes; fi; done
	if [ $filemissing = no ]
	then
		SCRIPTSTORUNNUMBER=$(( SCRIPTSTORUNNUMBER + 1 ))
		break
	else
		SCRIPTSTORUNNUMBER=$(( SCRIPTSTORUNNUMBER + 1 ))
	fi
done

	scriptname=$PIPELINETEMPFOLDER/$ID.delete.intermediates.sh
	echo "
#!/bin/bash
#$ -S /bin/bash
#$ -o $PIPELINETEMPFOLDER
#$ -e $PIPELINETEMPFOLDER
#$ -cwd
#$ -l tmem=$DEFAULTTMEM,h_vmem=$DEFAULTHVMEM
#$ -l h_rt=$DEFAULTNHOURS:0:0
#$ -V
#$ -R y	
" > $scriptname
if [ $OLDCLUSTER = yes ]
then
	echo "#$ -l scr=$DEFAULTSCRATCH" >> $scriptname
else
	echo "#$ -l tscr=$DEFAULTSCRATCH" >> $scriptname
fi
	echo set +e >> $scriptname
	# this should switch off errexit to prevent script exiting by default if no proper exit code from child process
	for (( i=0; i<  $SCRIPTNUMBER - $SCRIPTSTORUNNUMBER -1; i++ ))
	do
		writtenfiles=${WRITTENFILES[$i]}
		for f in $writtenfiles; do echo rm $PIPELINEHOMEFOLDER/${OUTPUTFOLDER[$i]}/$f >> $scriptname; done
	done
	if [ "$DELETEINTERMEDIATES" = "yes" ]
	then
		qsub -N $scriptname $scriptname
	fi


# then write the scripts 
# to do this, read a script till getting to COMMANDS then use the lines below
# write the header for qsub
# then write all the variables to be set, whether or not that particular script will use them 
# every script will first check whether all its output files exist and if so will exit reporting its job is completed
# next will check if all input files exist and if not exit reporting an error 
# then the script is running and will write a file saying it is running
# there is a problem that this file will not be deleted if the script ends prematurely, so maybe don't use this after all

for (( i=$SCRIPTNUMBER - $SCRIPTSTORUNNUMBER; i<$SCRIPTNUMBER; i++ ))
do
	scriptname=$PIPELINETEMPFOLDER/$ID.$PIPELINENAME.${SCRIPTARRAY[$i]}.sh
	echo "
#!/bin/bash
#$ -S /bin/bash
#$ -o $PIPELINETEMPFOLDER
#$ -e $PIPELINETEMPFOLDER
#$ -cwd
" > $scriptname
# At times the new cluster has produced an error message saying it cannot output to a folder. 
# At other times it has worked fine.
	if [ $OLDCLUSTER = yes ]
	then
		echo "#$ -l scr=${SCRATCH[$i]}" >> $scriptname
	else
		echo "#$ -l tscr=${SCRATCH[$i]}" >> $scriptname
	fi
	if [ ${NCORES[$i]} -gt 1 ]
	then
	echo "#$ -pe smp ${NCORES[$i]}" >> $scriptname
	fi
	echo "#$ -l tmem=${TMEM[$i]},h_vmem=${HVMEM[$i]}
#$ -l h_rt=${NHOURS[$i]}:0:0
#$ -V
#$ -R y	
" >> $scriptname

echo set +e >> $scriptname
# this should switch off errexit to prevent script exiting by default if no proper exit code from child process

# here is where to write all the variables which need to be set
if [ ! -z "$PIPELINEPARSFILE" ]
then
	echo "
echo # Following are all pipeline variables, not necessarily relevant to this script
source $PIPELINEPARSFILE
" >> $scriptname
	source $PIPELINEPARSFILE
	# I need to use it in this script too because variables will be expanded in commands below
fi
for (( v=0; v<$NVARIABLESFORSCRIPTS; v++))
do
	var=${VARIABLESFORSCRIPTS[$v]}
	echo $var=\"${!var}\" >> $scriptname
done
for vararray in INPUTFOLDER OUTPUTFOLDER TEMPFOLDER INPUTFILES OUTPUTFILES WRITTENFILES HVMEM TMEM NCORES SCRATCH NHOURS
do
	eval var=$vararray[$i]
	echo $vararray=\"${!var}\" >> $scriptname
	# hope this works OK
done
echo ID=$ID >> $scriptname
echo "
mkdir $PIPELINEHOMEFOLDER/${TEMPFOLDER[$i]}
mkdir $PIPELINEHOMEFOLDER/${OUTPUTFOLDER[$i]}
" >> $scriptname

# code to check re input files and output files
# if all output files exist and seem to be OK then exit with message
# if all input files not present then exit with error
	echo "
set -x
cd $PIPELINEHOMEFOLDER/${OUTPUTFOLDER[$i]}
outfiles=\"${OUTPUTFILES[$i]}\"
alldone=yes
for f in \$outfiles; do if [ ! -s \$f -o ! -e \$f ]; then alldone=no; fi; done
if [ \$alldone = yes ]
then
	echo No need to run $scriptname because all output files exist:
	echo \$outfiles
	exit 1
fi
" >> $scriptname

# now test to see if any downstream script has all output files so don't need to run this one
# this can happen if multiple attempts are made at running the whole pipeline because intermediate files may have been deleted
for (( d=$i + 1; d<$SCRIPTNUMBER; ++d ))
do
echo "
	if [ -e $PIPELINEHOMEFOLDER/${OUTPUTFOLDER[$d]} ]
	then
		cd $PIPELINEHOMEFOLDER/${OUTPUTFOLDER[$d]}
		alldone=yes
		for f in ${OUTPUTFILES[d]} ; do if [ ! -e \$f -o ! -s \$f ]; then alldone=no; fi; done
		if [ \$alldone = yes ]
		then
			echo No need to run $scriptname because all output files of downstream script $ID.$PIPELINENAME.${SCRIPTARRAY[$d]}.sh exist:
			echo ${INPUTFILES[d]}
			exit 2
		fi
	fi
" >> $scriptname
done

echo "
# if only some outfiles to be written exist, delete all of them
cd $PIPELINEHOMEFOLDER/${OUTPUTFOLDER[$i]}
writtenfiles=\"${WRITTENFILES[$i]}\"
for f in \$writtenfiles; do if [ -e \$f ]; then rm \$f; fi; done
# do the same for any created in temporary folder
cd $PIPELINEHOMEFOLDER/${TEMPFOLDER[$i]}
writtenfiles=\"${WRITTENFILES[$i]}\"
for f in \$writtenfiles; do if [ -e \$f ]; then rm \$f; fi; done


cd $PIPELINEHOMEFOLDER/${INPUTFOLDER[$i]}
infiles=\"${INPUTFILES[$i]}\"
for f in \$infiles
do 
	if [ ! -e \$f -o ! -s \$f ]
	then 
		echo Error in $scriptname, input file \$f  does not exist
		exit 3
	fi 
done	
" >> $scriptname
	oncommands=no
	cat $PIPELINESCRIPTSFOLDER/${SCRIPTARRAY[$i]} | while read line
	do
		if [ "$line" = "COMMANDS" ]
		then
			oncommands=yes
		else
			if [ $oncommands = yes ]
			then
				echo "$line" >> $scriptname
			fi
		fi
	done

# check if all output files created OK and if not delete all of them
	echo "
cd $PIPELINEHOMEFOLDER/${OUTPUTFOLDER[$i]}
outfiles=\"${OUTPUTFILES[$i]}\"
alldone=yes
for f in \$outfiles; do if [ ! -s \$f ]; then rm \$f; fi; done
for f in \$outfiles; do if [ ! -e \$f ]; then alldone=no; fi; done
if [ \$alldone = no ]
then
	echo Error in $scriptname - not all output files were created correctly
	# incomplete outfiles are not at present deleted so as to help subsequent debugging
	# if they were, would only delete outfiles which are not also infiles
else 
	echo  $scriptname completed OK, wrote all outfiles: \$outfiles
fi
" >> $scriptname
if [ $i -eq $(( SCRIPTNUMBER - 1 )) ]
then
	echo "
if [ \$alldone = yes ]
then
	for f in ${OUTPUTFILES[$i]}
	do 
		chmod 440 \$f
	done
fi	
" >> $scriptname
fi
# also delete input files if DELETEINTERMEDIATES=yes
if [ DELETEINTERMEDIATES = yes -a $i -gt 0 ] 
then
	echo "
 # deleting intermediate files, i.e. those which were input but not output
alldone=yes
for f in \$outfiles; do if [ ! -e \$f ]; then alldone=no; fi; done
if [ \$alldone = yes ]
then
	cd $PIPELINEHOMEFOLDER/${INPUTFOLDER[$i]}
	for f in ${INPUTFILES[$i]}
	do
		if [ ${INPUTFOLDER[$i]} = ${INPUTFOLDER[$i]} ]
		then
			todelete=yes
			for ff in ${INPUTFILES[$i]}
			do
				if [ \$f = \$ff] ; then todelete=no; fi
			done
			if [ \$todelete = yes ] ; then rm \$f; fi 
		else
			rm \$f
		fi
	done
fi
" >> $scriptname
fi

done
# all scripts written

exit

lastjobname=""
for (( attempt=1; attempt<=$ATTEMPTS; ++attempt ))
do
# submit all the scripts
# keep a list of the jobs so they can be qdel'd
	for (( i=$SCRIPTNUMBER - $SCRIPTSTORUNNUMBER; i<$SCRIPTNUMBER; i++ ))
	do
		scriptname=$PIPELINETEMPFOLDER/$ID.$PIPELINENAME.${SCRIPTARRAY[$i]}.sh
		jobname=$ID.$PIPELINENAME.${SCRIPTARRAY[$i]}.$attempt
		if [ "$lastjobname" = "" ]
		then
			echo qsub -N $jobname $scriptname
			qsub -N $jobname $scriptname
		else
			echo qsub -N $jobname -hold_jid $lastjobname $scriptname
			qsub -N $jobname -hold_jid $lastjobname $scriptname
		fi
		lastjobname=$jobname
	done

done
#end of loop for attempts



done
# end of loop for reading IDs

