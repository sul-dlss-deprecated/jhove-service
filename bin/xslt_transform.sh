#!/bin/sh
source=$1
target=$2
transforms=`dirname $0`
xslt=$3
xslthaspath=`echo $xslt | grep -c '/'`
if [ $xslthaspath -eq 0 ]
then
	xslt=$transforms/$3
fi
/usr/bin/java -jar $transforms/saxon9.jar -s:$source -o:$target \
	-xsl:$xslt $4 $5 $6 $7 $8

