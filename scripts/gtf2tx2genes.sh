# a simple script to extract a tx2genes table from a gtf file

cat annotations.gtf | grep -e "\Wtranscript\W" | cut -f 9 | cut -d';' -f1-2 | sed -e 's/gene_id //' -e 's/transcript_id //' -e 's/ //' | awk -F';' 'BEGIN{print "TXNAME,GENEID"}; {print $2 "," substr($1,0,16) "\""}' > tx2genes.csv
