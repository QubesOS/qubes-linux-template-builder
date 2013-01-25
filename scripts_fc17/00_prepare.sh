#!/bin/sh

rm -f keys base_rpms
ln -sf keys_$DIST keys
ln -sf base_rpms_$DIST base_rpms
