#!/bin/sh

########################################################################
# JHOVE - JSTOR/Harvard Object Validation Environment
# Copyright 2003-2005 by JSTOR and the President and Fellows of Harvard College
# JHOVE is made available under the GNU General Public License (see the
# file LICENSE for details)
#
# Usage: jhove [-c config] [-m module] [-h handler] [-e encoding] [-H handler]
#              [-o output] [-x saxclass] [-t tempdir] [-b bufsize]
#              [-l loglevel] [[-krs] dir-file-or-uri [...]]
#
# where -c config   Configuration file pathname
#       -m module   Module name
#       -h handler  Output handler name (defaults to TEXT)
#       -e encoding Character encoding of output handler (defaults to UTF-8)
#       -H handler  About handler name
#       -o output   Output file pathname (defaults to standard output)
#       -x saxclass SAX parser class (defaults to J2SE 1.4 default)
#       -t tempdir  Temporary directory in which to create temporary files
#       -b bufsize  Buffer size for buffered I/O (defaults to J2SE 1.4 default)
#       -k          Calculate CRC32, MD5, and SHA-1 checksums
#       -r          Display raw data flags, not textual equivalents
#       -s          Format identification based on internal signatures only
#       dir-file-or-uri Directory, file pathname or URI of formatted content
#
# CHANGE for JHOVE 1.8:
# You no longer have to figure out where JAVA_HOME is; that's the
# operating system's job. If the OS tells you it can't find Java,
# adjust your shell's path or revert to the old way (commented out).
# Configuration constants:

JHOVE_HOME=`dirname $0`
JHOVE_VERSION=1.20.1

export JHOVE_HOME
JAVA_HOME=/etc/alternatives/jre
JAVA=/usr/bin/java

CP=${JHOVE_HOME}/jhove-apps-${JHOVE_VERSION}.jar:${JHOVE_HOME}/jhove-ext-modules-${JHOVE_VERSION}.jar

# Retrieve a copy of all command line arguments to pass to the application.
# Since looping over the positional parameters is such a common thing to do in scripts,
#   for arg
# defaults to
#   for arg in "$@".
# The double-quoted "$@" is special magic that causes each parameter to be used as a single word

ARGS="-c ${JHOVE_HOME}/jhove.conf"
for ARG do
    ARGS="$ARGS $ARG"
done

# Set the CLASSPATH and invoke the Java loader.
${JAVA} -Xms128M -Xmx6000M -classpath $CP Jhove $ARGS
