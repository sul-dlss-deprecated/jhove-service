#!/bin/sh

JHOVE_HOME=`dirname $0`
export JHOVE_HOME
JAVA_HOME=/etc/alternatives/jre
JAVA=/usr/bin/java

CP=${JHOVE_HOME}/jhoveToolkit.jar:${JHOVE_HOME}/xmlTools.jar:${JHOVE_HOME}/xom-1.1.jar:${JHOVE_HOME}/JhoveApp.jar 

# Retrieve a copy of all command line arguments to pass to the application.

ARGS=""
for ARG do
    ARGS="$ARGS $ARG"
done

# Set the CLASSPATH and invoke the Java loader.
${JAVA} -Xms128M -Xmx3000M -classpath $CP edu.stanford.sulair.jhove.JhoveCommandLine $ARGS
