#!/bin/bash
echo executing as $(whoami)
cp -Rf /artifacts/* /deployments/.m2/repository/
grep -lrnw /deployments/.m2/repository/ -e '\\u0000' | xargs rm
if [ "x$NAMESPACE_NAME" == "x" ]; then
    UUID=$(cat /proc/sys/kernel/random/uuid)
    OPENSHIFT_NAMESPACE=$NAMESPACE_PREFIX-$(echo $UUID | tail -c 5)
else
    OPENSHIFT_NAMESPACE=$NAMESPACE_NAME
fi
export OPENSHIFT_NAMESPACE
echo $OPENSHIFT_NAMESPACE > /tmp/namespace
echo "----------"
env
echo "----------"
if [ "x$TEST_EXPR" == "x" ]; then
    mvn clean test -Dmaven.repo.local=/deployments/.m2/repository -s $MVN_SETTINGS_PATH -P$MVN_PROFILES -B $MVN_ARGS -DargLine="$MVN_SUREFIRE_ARGLINE" -Dxtf.config.is.namespace=$OPENSHIFT_NAMESPACE -Dxtf.openshift.namespace=$OPENSHIFT_NAMESPACE -Dxtf.bm.namespace=$OPENSHIFT_NAMESPACE
else
    mvn clean test -Dmaven.repo.local=/deployments/.m2/repository -s $MVN_SETTINGS_PATH -P$MVN_PROFILES -B $MVN_ARGS -DargLine="$MVN_SUREFIRE_ARGLINE" -Dtest=$TEST_EXPR -Dxtf.config.is.namespace=$OPENSHIFT_NAMESPACE -Dxtf.openshift.namespace=$OPENSHIFT_NAMESPACE -Dxtf.bm.namespace=$OPENSHIFT_NAMESPACE
fi

if [ "x$SUREFIRE_REPORTS_DEST_FOLDER" == "x" ]; then
    echo "surefire reports are not copied, please fill SUREFIRE_REPORTS_DEST_FOLDER env variable"
else
    DST_FOLDER=$SUREFIRE_REPORTS_DEST_FOLDER/$OPENSHIFT_NAMESPACE
    echo "copying surefire reports $SUREFIRE_REPORTS_DEST_FILES from $SUREFIRE_REPORTS_FOLDER to $DST_FOLDER"
    [ ! -d $DST_FOLDER ] && mkdir -p $DST_FOLDER
    cp -ra $SUREFIRE_REPORTS_FOLDER/$SUREFIRE_REPORTS_DEST_FILES $DST_FOLDER/ 2>/dev/null || :

    if [ -d "/deployments/xpaas-qe/test-fuse/log" ]; then
      LOG_DEST_FOLDER=$LOG_DEST_FOLDER/$OPENSHIFT_NAMESPACE
      [ ! -d "$LOG_DEST_FOLDER" ] && mkdir -p $LOG_DEST_FOLDER
      echo "copying logs from /deployments/xpaas-qe/test-fuse/log to $LOG_DEST_FOLDER"
      cp -ra /deployments/xpaas-qe/test-fuse/log $LOG_DEST_FOLDER/ 2>/dev/null || :
    fi

fi
tail -f /dev/null
