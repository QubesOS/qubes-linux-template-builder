#!/bin/sh
APPSORIG=$1
APPSTMPL=$2

if [ $# != 2 ]; then
    echo "usage $0 <apps_orig_dir> <apps_templ_dir>"
    exit 0
fi

rm -f $APPSTMPL/*
mkdir -p $APPSTMPL
find $APPSORIG/ -name "*.desktop" -exec ./convert_app2template.sh {} $APPSTMPL \;
