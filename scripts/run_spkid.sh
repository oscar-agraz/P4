#!/bin/bash

# Scripting is very useful to repeat tasks, as testing different configuration, multiple files, etc.
# This bash script is provided as one example
# Please, adapt at your convinience, add cmds, etc.
# Antonio Bonafonte, Nov. 2015

## @file
# \TODO
# Set the proper value to variables: lists, w, name_exp and db
# - lists:    directory with the list of signal files
# - w:        a working directory for temporary files
# - name_exp: name of the experiment
# - db:       directory of the speecon database 
# \DONE
lists=lists
w=work
name_exp=one
db=spk_ima/speecon

# ------------------------
# Usage
# ------------------------

if [[ $# < 1 ]]; then
   echo "Empleo: $0 command..."
   echo ""
   echo "Where command can be one or more of the following (in this order):"
   echo ""
   echo "     FEAT: where FEAT is the name of a feature (eg. lp, lpcc or mfcc)."
   echo "           - A function with the name compute_FEAT() must be defined."
   echo "           - Initially, only compute_lp() exists and can be used."
   echo "           - Edit this file to add your own features."
   echo ""
   echo "     train: train GMM for speaker recognition and/or verification"
   echo "      test: test GMM in speaker recognition"
   echo "  classerr: count errors in speaker recognition"
   echo "trainworld: estimate world model for speaker verification"
   echo "    verify: test gmm in verification task"
   echo " verifyerr: count errors of verify"
   echo "finalclass: reserved for final test in the classification task"
   echo "finalverif: reserved for final test in the verification task"
   exit 1
fi


# ------------------------
# Check directories
# ------------------------

if [[ -z "$w" ]]; then echo "Edit this script and set variable 'w'"; exit 1; fi
mkdir -p $w  #Create directory if it does not exists
if [[ $? -ne 0 ]]; then echo "Error creating directory $w"; exit 1; fi

if [[ ! -d "$db" ]]; then
   echo "Edit this script and set variable 'db' to speecon db"
   exit 1
fi


# ------------------------
# Check if gmm_train is in path
# ------------------------
type gmm_train > /dev/null
if [[ $? != 0 ]] ; then
   echo "Set PATH to include PAV executable programs ... "
   echo "Maybe modify ~/.bashrc or ~/.profile ..."
   exit 1
fi 
# Now, we assume that all the path for programs are already in the path 

# ----------------------------
# Feature extraction functions
# ----------------------------

## @file
# \TODO
# Create your own features with the name compute_$FEAT(), where  $FEAT the name of the feature.
# - Select (or change) different features, options, etc. Make you best choice and try several options.
# \DONE

compute_lp() {
    for filename in $(cat $lists/class/all.train $lists/class/all.test); do
        mkdir -p `dirname $w/$FEAT/$filename.$FEAT`
        EXEC="wav2lp 8 $db/$filename.wav $w/$FEAT/$filename.$FEAT"
        echo $EXEC && $EXEC || exit 1
    done
}

compute_lpcc() {
    for filename in $(cat $lists/class/all.train $lists/class/all.test); do
        mkdir -p `dirname $w/$FEAT/$filename.$FEAT`
        EXEC="wav2lpcc 8 13 $db/$filename.wav $w/$FEAT/$filename.$FEAT"
        echo $EXEC && $EXEC || exit 1
    done
}

compute_mfcc() {
    for filename in $(cat $lists/class/all.train $lists/class/all.test); do
        mkdir -p `dirname $w/$FEAT/$filename.$FEAT`
        EXEC="wav2mfcc 16 24 $db/$filename.wav $w/$FEAT/$filename.$FEAT"
        echo $EXEC && $EXEC || exit 1
    done
}

#compute_olddelta() {
#    for filename in $(cat $lists/class/all.train $lists/class/all.test); do
#        mkdir -p `dirname $w/$FEAT/$filename.$FEAT`
#        EXEC="wav2olddelta 16 24 $db/$filename.wav $w/$FEAT/$filename.mfcc $w/$FEAT/$filename.delta_raw $w/$FEAT/$filename.$FEAT"
#        echo $EXEC && $EXEC || exit 1
#    done

compute_delta() {
    for filename in $(cat $lists/class/all.train $lists/class/all.test); do
        mkdir -p `dirname $w/$FEAT/$filename.$FEAT`
        EXEC="wav2delta 16 24 $db/$filename.wav $w/$FEAT/$filename.mfcc $w/$FEAT/$filename.delta_raw $w/$FEAT/$filename.static $w/$FEAT/$filename.d1 $w/$FEAT/$filename.d2"
        echo $EXEC && $EXEC || exit 1
    done
}

#Falta compute lpcc y mfcc


#  Set the name of the feature (not needed for feature extraction itself)
if [[ ! -v FEAT && $# > 0 && "$(type -t compute_$1)" = function ]]; then
	FEAT=$1
elif [[ ! -v FEAT ]]; then
	echo "Variable FEAT not set. Please rerun with FEAT set to the desired feature."
	echo
	echo "For instance:"
	echo "    FEAT=mfcc $0 $*"

	exit 1
fi

# ---------------------------------
# Main program: 
# For each cmd in command line ...
# ---------------------------------


for cmd in $*; do
   echo `date`: $cmd '---';

   if [[ $cmd == train ]]; then
       ## @file
	   # \TODO
	   # Select (or change) good parameters for gmm_train
       # \DONE
       for dir in $db/BLOCK*/SES* ; do
           name=${dir/*\/}
           echo $name ----
           gmm_train -v 1 -T 0.00001 -N 10000 -i 2 -d $w/$FEAT -e $FEAT -m 64 -g $w/gmm/$FEAT/$name.gmm $lists/class/$name.train || exit 1
           echo
       done

    elif [[ $cmd == train_delta ]]; then
        for dir in $db/BLOCK*/SES* ; do
           name=${dir/*\/}
           echo $name ----
           gmm_train -v 1 -T 0.00001 -N 10000 -i 2 -d $w/delta -e static -m 64 -g $w/gmm/static/$name.gmm $lists/class/$name.train || exit 1
           echo
       done
        for dir in $db/BLOCK*/SES* ; do
           name=${dir/*\/}
           echo $name ----
           gmm_train -v 1 -T 0.00001 -N 10000 -i 2 -d $w/delta -e d1 -m 64 -g $w/gmm/d1/$name.gmm $lists/class/$name.train || exit 1
           echo
       done
        for dir in $db/BLOCK*/SES* ; do
           name=${dir/*\/}
           echo $name ----
           gmm_train -v 1 -T 0.00001 -N 10000 -i 2 -d $w/delta -e d2 -m 64 -g $w/gmm/d2/$name.gmm $lists/class/$name.train || exit 1
           echo
       done

    elif [[ $cmd == test ]]; then
       #find $w/gmm/$FEAT -name '*.gmm' -printf '%P\n' | perl -pe 's/.gmm$//' | sort  > $lists/gmm.list
       (gmm_classify -d $w/$FEAT -e $FEAT -D $w/gmm/$FEAT -E gmm $lists/gmm.list  $lists/class/all.test | tee $w/class_${FEAT}_${name_exp}.log) || exit 1

   elif [[ $cmd == classerr ]]; then
       if [[ ! -s $w/class_${FEAT}_${name_exp}.log ]] ; then
          echo "ERROR: $w/class_${FEAT}_${name_exp}.log not created"
          exit 1
       fi
       # Count errors
       perl -ne 'BEGIN {$ok=0; $err=0}
                 next unless /^.*SA(...).*SES(...).*$/; 
                 if ($1 == $2) {$ok++}
                 else {$err++}
                 END {printf "nerr=%d\tntot=%d\terror_rate=%.2f%%\n", ($err, $ok+$err, 100*$err/($ok+$err))}' $w/class_${FEAT}_${name_exp}.log | tee -a $w/class_${FEAT}_${name_exp}.log
   elif [[ $cmd == trainworld ]]; then
       ## @file
	   # \TODO
	   # Implement 'trainworld' in order to get a Universal Background Model for speaker verification
	   #
	   # - The name of the world model will be used by gmm_verify in the 'verify' command below.
           gmm_train -v 1 -T 0.00001 -N 10000 -i 2 -d $w/$FEAT -e $FEAT -m 64 -g $w/gmm/$FEAT/world.gmm $lists/verif/users_and_others.train || exit 1
       # \DONE

   elif [[ $cmd == verify ]]; then
       ## @file
	   # \TODO 
	   # Implement 'verify' in order to perform speaker verification
	   #
	   # - The standard output of gmm_verify must be redirected to file $w/verif_${FEAT}_${name_exp}.log.
	   #   For instance:
	   #   * <code> gmm_verify ... > $w/verif_${FEAT}_${name_exp}.log </code>
	   #   * <code> gmm_verify ... | tee $w/verif_${FEAT}_${name_exp}.log </code>
       # \DONE
       
       gmm_verify  -d $w/$FEAT -e $FEAT -D $w/gmm/$FEAT -E gmm  -w world $lists/gmm.list  $lists/verif/all.test $lists/verif/all.test.candidates | tee $w/verif_${FEAT}_${name_exp}.log

   elif [[ $cmd == verifyerr ]]; then
       if [[ ! -s $w/verif_${FEAT}_${name_exp}.log ]] ; then
          echo "ERROR: $w/verif_${FEAT}_${name_exp}.log not created"
          exit 1
       fi
       # You can pass the threshold to spk_verif_score.pl or it computes the
       # best one for these particular results.
       spk_verif_score $w/verif_${FEAT}_${name_exp}.log | tee $w/verif_${FEAT}_${name_exp}.res

   elif [[ $cmd == finalclass ]]; then
       ## @file
	   # \TODO
	   # Perform the final test on the speaker classification of the files in spk_ima/sr_test/spk_cls.
	   # The list of users is the same as for the classification task. The list of files to be
	   # recognized is lists/final/class.test
       #echo "To be implemented ..."

       #Feature extraction
       for filename in $(cat $lists/final/class.test); do
            mkdir -p `dirname $w/final/$filename.lpcc`
            EXEC="wav2lpcc 8 13 spk_ima/sr_test/$filename.wav $w/final/$filename.lpcc"
            echo $EXEC && $EXEC || exit 1
       done  


       #find $w/gmm/$FEAT -name '*.gmm' -printf '%P\n' | perl -pe 's/.gmm$//' | sort  > $lists/gmm.list
       (gmm_classify -d $w/final -e $FEAT -D $w/gmm/$FEAT -E gmm $lists/gmm.list  $lists/final/class.test | tee $w/class_test.log) || exit 1

       if [[ ! -s $w/class_test.log ]] ; then
          echo "ERROR: $w/class_test.log not created"
          exit 1
       fi

       # Count errors
       perl -ne 'BEGIN {$ok=0; $err=0}
                 next unless /^.*SA(...).*SES(...).*$/; 
                 if ($1 == $2) {$ok++}
                 else {$err++}
                 END {printf "nerr=%d\tntot=%d\terror_rate=%.2f%%\n", ($err, $ok+$err, 100*$err/($ok+$err))}' $w/class_test.log | tee -a $w/class_test.log

   
   elif [[ $cmd == finalverif ]]; then
       ## @file
	   # \TODO
	   # Perform the final test on the speaker verification of the files in spk_ima/sr_test/spk_ver.
	   # The list of legitimate users is lists/final/verif.users, the list of files to be verified
	   # is lists/final/verif.test, and the list of users claimed by the test files is
	   # lists/final/verif.test.candidates
       #echo "To be implemented ..."
        for filename in $(cat $lists/final/verif.test); do
            mkdir -p `dirname $w/final/$filename.mfcc`
            EXEC="wav2mfcc 16 24 spk_ima/sr_test/$filename.wav $w/final/$filename.mfcc"
            echo $EXEC && $EXEC || exit 1
       done  

       gmm_verify  -d $w/final -e $FEAT -D $w/gmm/$FEAT -E gmm  -w world $lists/gmm.list  $lists/final/verif.test $lists/final/verif.test.candidates | tee $w/verif_pre_test.log 
       
       perl -ane 'print "$F[0]\t$F[1]\t"; if ($F[2] > -3.214) {print "1\n"} else {print "0\n"}' $w/verif_pre_test.log | tee $w/verif_test.log

       if [[ ! -s $w/verif_test.log ]] ; then
          echo "ERROR: $w/verif_test.log not created"
          exit 1
       fi

       spk_verif_score $w/verif_pre_test.log | tee $w/verif_test.res
       

       
   
   # If the command is not recognize, check if it is the name
   # of a feature and a compute_$FEAT function exists.
   elif [[ "$(type -t compute_$cmd)" = function ]]; then
	   FEAT=$cmd
       compute_$FEAT       
   else
       echo "undefined command $cmd" && exit 1
   fi
done

date

exit 0
