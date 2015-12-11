#!/bin/bash

rm job*.out

for (( i=1; i <= 3; i++ ))
do  
if [ $i -eq 1 ]
then
	qsub -N job1.$i job1.sh
else
	qsub -N job1.$i -hold_jid job3.$((i-1)) job1.sh
fi
qsub -hold_jid job1.$i -N job2.$i job2.sh
qsub  -hold_jid job2.$i -N job3.$i job3.sh
done


