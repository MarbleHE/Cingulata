#!/bin/bash

#
#    (C) Copyright 2017 CEA LIST. All Rights Reserved.
#    Contributor(s): Cingulata team (formerly Armadillo team)
#
#    This software is governed by the CeCILL-C license under French law and
#    abiding by the rules of distribution of free software.  You can  use,
#    modify and/ or redistribute the software under the terms of the CeCILL-C
#    license as circulated by CEA, CNRS and INRIA at the following URL
#    "http://www.cecill.info".
#
#    As a counterpart to the access to the source code and  rights to copy,
#    modify and redistribute granted by the license, users are provided only
#    with a limited warranty  and the software's author,  the holder of the
#    economic rights,  and the successive licensors  have only  limited
#    liability.
#
#    The fact that you are presently reading this means that you have had
#    knowledge of the CeCILL-C license and that you accept its terms.
#

: ' :
This script takes as input two IPv4 adresses and compute if they are equal.

Example:
./run.sh 192.168.3.5 192.168.3.5
: ' :

CURR_DIR=$PWD
FILE=ipv4

APPS_DIR=$CURR_DIR/../../apps/
mkdir -p input
rm -f input/*.ct
mkdir -p output
rm -f output/*.ct


# Convert an IPv4 adress to its decimal equivalent.
ipv4dec ()
{
	declare -i a b c d;
	IFS=. read a b c d <<<"$1";
	echo $(( (a<<24)+(b<<16)+(c<<8)+d ));
}

# Generate keys
echo "FHE key generation"
$APPS_DIR/generate_keys

echo "Input encryption"
NR_THREADS=$(nproc)

# Encrypt IP1
TMP=`$APPS_DIR/helper --bit-cnt 32 --prefix input/i:a_ --idx-places 0 --start-idx 0 $(ipv4dec $1)`
$APPS_DIR/encrypt -v --public-key fhe_key.pk  --threads $NR_THREADS $TMP

# Encrypt IP2
TMP=`$APPS_DIR/helper --bit-cnt 32 --prefix input/i:b_ --idx-places 0 --start-idx 0 $(ipv4dec $2)`
$APPS_DIR/encrypt -v --public-key fhe_key.pk  --threads $NR_THREADS $TMP

echo "Homomorphic execution..."
time $APPS_DIR/dyn_omp $FILE'-opt.blif' --threads $NR_THREADS

echo "Output decryption"
OUT_FILES=`ls -v output/*`
$APPS_DIR/helper --from-bin --bit-cnt 1 --msb-first `$APPS_DIR/decrypt --secret-key fhe_key.sk $OUT_FILES`

