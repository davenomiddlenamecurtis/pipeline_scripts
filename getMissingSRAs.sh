cd $PROJECTDIR/newdownloads

first=yes

cat $PROJECTDIR/SSSDNM/manifest_36857_11-09-2015_s.txt | while read one two three four five six seven eight rest
do
	if [ first = yes ]
	then
		first=no
		continue
	else
		
		if [ ! -e $PROJECTDIR/SSSDNM/bam/${five}_sorted_unique.bam ]
		then
			s=${one##*/}
			s=${s%.sra}
			echo prefetch --ascp-path "/share/apps/genomics/ascp-3.5.4.102989/ascp|/home/rejudcu/ascp/asperaweb_id_dsa.openssh" $s
			prefetch --ascp-path "/share/apps/genomics/ascp-3.5.4.102989/ascp|/home/rejudcu/ascp/asperaweb_id_dsa.openssh" $s
		fi
	fi
done

