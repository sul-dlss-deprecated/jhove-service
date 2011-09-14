#!/bin/sh

testdir=/dor/workspace/test/transform-test
source=$testdir/transforms_test_data/jhove_raw_dr_jf822ps0564.xml
output=$testdir/output/jhove-filtered_dr_jf822ps0564.xml

transforms=`dirname $0`
$transforms/xslt_transform.sh  $source $output jhove-filter.xsl
less $output