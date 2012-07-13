#!/bin/sh

JHOVE_HOME=`dirname $0`
export JHOVE_HOME
JAVA_HOME=/etc/alternatives/jre
JAVA=/usr/bin/java

CP=${JHOVE_HOME}/jhoveToolkit.jar:${JHOVE_HOME}/JhoveApp.jar

# Retrieve a copy of all command line arguments to pass to the application.
# Since looping over the positional parameters is such a common thing to do in scripts,
#   for arg
# defaults to
#   for arg in "$@".
# The double-quoted "$@" is special magic that causes each parameter to be used as a single word

ARGS=""
for ARG do
    ARGS="$ARGS $ARG"
done

# Set the CLASSPATH and invoke the Java loader.
${JAVA} -Xms128M -Xmx3000M -classpath $CP $ARGS
