#!/bin/bash

## \file
## \TODO This file implements a very trivial feature extraction; use it as a template for other front ends.
## 
## Please, read SPTK documentation and some papers in order to implement more advanced front ends.
# \DONE

# Base name for temporary files
base=/tmp/$(basename $0).$$ 

# Ensure cleanup of temporary files on exit
trap cleanup EXIT
cleanup() {
   \rm -f $base.*
}

if [[ $# != 6 ]]; then
   echo "$0 mfcc_order mfcc_numfilters input.wav output.mfcc output.delta_raw output.delta"
   exit 1
fi

mfcc_order=$1
mfcc_numfilters=$2
inputfile=$3
outputfile_mfcc=$4
outputfile_delta_raw=$5
outputfile_delta=$6

UBUNTU_SPTK=1
if [[ $UBUNTU_SPTK == 1 ]]; then
   # In case you install SPTK using debian package (apt-get)
   X2X="sptk x2x"
   FRAME="sptk frame"
   WINDOW="sptk window"
   MFCC="sptk mfcc"
   DELTA="sptk delta"
else
   # or install SPTK building it from its source
   X2X="x2x"
   FRAME="frame"
   MFCC="mfcc"
   DELTA="delta"
fi

# Main command for feature extration
sox $inputfile -t raw - dither -p12 | $X2X +sf | $FRAME -l 400 -p 80 |\
	$MFCC -l 400 -m $mfcc_order -n $mfcc_numfilters > $base.mfcc 

# Our array files need a header with the number of cols and rows:
ncol=$((mfcc_order)) # lpc p =>  (gain a1 a2 ... ap) 
nrow=`$X2X +fa < $base.mfcc | wc -l | perl -ne 'print $_/'$ncol', "\n";'`

# Build fmatrix file by placing nrow and ncol in front, and the data after them
echo $nrow $ncol | $X2X +aI > $outputfile_mfcc
cat $base.mfcc >> $outputfile_mfcc 



# Main command for feature extration
$DELTA -m 15 -r 2 1 1 $outputfile_mfcc > $base.delta_raw

# Our array files need a header with the number of cols and rows:
ncol=$((mfcc_order+1)) # lpc p =>  (gain a1 a2 ... ap) 
nrow=`$X2X +fa < $base.delta_raw | wc -l | perl -ne 'print $_/'$ncol', "\n";'`

# Build fmatrix file by placing nrow and ncol in front, and the data after them
echo $nrow $ncol | $X2X +aI > $outputfile_delta_raw
cat $base.delta_raw >> $outputfile_delta_raw

fmatrix_delta -f 3 $outputfile_delta_raw $base.delta
cat $base.delta >> $outputfile_delta

exit
