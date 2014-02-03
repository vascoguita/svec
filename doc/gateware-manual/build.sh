#!/bin/bash

cd drawings; find . -name "*.eps" | xargs -n 1 epstopdf; cd ..
REVISION=`git describe HEAD`
echo "@set git-revision $REVISION"  > git_revision.in
make clean && make
evince svec-gateware-manual.pdf