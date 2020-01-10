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

# Infer JHOVE_HOME from script location
SCRIPT="${0}"

echo ${SCRIPT}

# Resolve absolute and relative symlinks
while [ -h "${SCRIPT}" ]; do
    LS=$( ls -ld "${SCRIPT}" )
    LINK=$( expr "${LS}" : '.*-> \(.*\)$' )
    if expr "${LINK}" : '/.*' > /dev/null; then
        SCRIPT="${LINK}"
    else
        SCRIPT="$( dirname "${SCRIPT}" )/${LINK}"
    fi
done

# Store absolute location
CWD="$( pwd )"
JHOVE_HOME="$( cd "$(dirname "${SCRIPT}" )" && pwd )"
cd "${CWD}" || exit
export JHOVE_HOME

JHOVE_VERSION=1.24.0-RC1
JAVA_HOME=/etc/alternatives/jre
JAVA=/usr/bin/java

CP=${JHOVE_HOME}/jhove-apps-${JHOVE_VERSION}.jar:${JHOVE_HOME}/jhove-ext-modules-${JHOVE_VERSION}.jar
CP=${CP}:${JHOVE_HOME}/aiff-hul-1.6.1-RC1.jar
CP=${CP}:${JHOVE_HOME}/ascii-hul-1.4.1.jar
CP=${CP}:${JHOVE_HOME}/gif-hul-1.4.2-RC1.jar
CP=${CP}:${JHOVE_HOME}/html-hul-1.4.1.jar
CP=${CP}:${JHOVE_HOME}/jpeg-hul-1.5.2-RC1.jar
CP=${CP}:${JHOVE_HOME}/jpeg2000-hul-1.4.2-RC1.jar
CP=${CP}:${JHOVE_HOME}/pdf-hul-1.12.2-RC1.jar
CP=${CP}:${JHOVE_HOME}/tiff-hul-1.9.2-RC1.jar
CP=${CP}:${JHOVE_HOME}/utf8-hul-1.7.1.jar
CP=${CP}:${JHOVE_HOME}/wave-hul-1.8.1-RC1.jar
CP=${CP}:${JHOVE_HOME}/xml-hul-1.5.1.jar

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

echo $JHOVE_HOME

# Set the CLASSPATH and invoke the Java loader.
${JAVA} -Xms128M -Xmx6000M -classpath $CP Jhove $ARGS
