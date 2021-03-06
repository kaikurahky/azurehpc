#!/bin/bash

INSTALL_DIR=/apps
RUN_DIR="$1"
CASE_NAME="$2"
NODES="$3"
PPN="$4"

source $INSTALL_DIR/OpenFOAM/setenv.sh

cd $RUN_DIR/$CASE_NAME

NP=$(($NODES * $PPN))

TARGET=${CASE_NAME}-${NODES}x${PPN}
echo "New case dir: $TARGET"

rsync -av --exclude polyMesh --exclude triSurface . ../$TARGET

cd ../$TARGET/constant
ln -s ../../$CASE_NAME/constant/polyMesh
ln -s ../../$CASE_NAME/constant/triSurface
cd ..

foamDictionary -entry numberOfSubdomains -set $NP system/decomposeParDict
foamDictionary -entry method -set multiLevel system/decomposeParDict
foamDictionary -entry multiLevelCoeffs -set "{}" system/decomposeParDict
foamDictionary -entry scotchCoeffs -set "{}" system/decomposeParDict
foamDictionary -entry multiLevelCoeffs.level0 -set "{}" system/decomposeParDict
foamDictionary -entry multiLevelCoeffs.level0.numberOfSubdomains -set $NODES system/decomposeParDict
foamDictionary -entry multiLevelCoeffs.level0.method -set scotch system/decomposeParDict
foamDictionary -entry multiLevelCoeffs.level1 -set "{}" system/decomposeParDict
foamDictionary -entry multiLevelCoeffs.level1.numberOfSubdomains -set $PPN system/decomposeParDict
foamDictionary -entry multiLevelCoeffs.level1.method -set scotch system/decomposeParDict

# Copy motorbike surface from resources directory
decomposePar -copyZero 2>&1 | tee log.decomposeParMultiLevel

