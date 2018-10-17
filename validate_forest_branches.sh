#!/bin/bash

function run_configs {
   branch=$1
   output=$(readlink -f $2)

   # checkout branch
   echo -e "checking out branch: $branch\n"
   git checkout $branch

   pushd HeavyIonsAnalysis/JetAnalysis/python/jets/

   # regenerate jet sequences
   rm ak*JetSequence_*_*_cff.py*
   ./makeJetSequences.sh

   popd

   # clean and rebuild
   # scram b distclean
   scram b -j4

   pushd HeavyIonsAnalysis/JetAnalysis/test/

   # run all foresting configs
   for config in $(ls runForestAOD_*.py); do
      # run all events for validation
      sed -i 's/input = cms.untracked.int32(1)/input = cms.untracked.int32(-1)/' $config

      echo -n "running config: $config ... "
      [[ cmsRun $config &> ${config%.*}.log ]] && {
         mv HiForestAOD.root $output/HiForestAOD_${config%.*}.root;
         echo -e "OK\n"; } || {
         echo -e "ERROR\n"; }
      mv ${config%.*}.log $output

      # revert change
      sed -i 's/input = cms.untracked.int32(-1)/input = cms.untracked.int32(1)/' $config
   done

   popd
}

ARGS=()

while [ $# -gt 0 ]; do
   case "$1" in 
      -d|--dir)      dir="$2"; shift 2 ;;
      --dir=*)       dir="${1#*=}"; shift ;;
      -n|--new)      newonly=1; shift ;;
      -r|--ref)      refonly=1; shift ;;
      -*|--*)        echo -e "invalid option: $1\n"; exit 1 ;;
      *)             ARGS+=("$1"); shift ;;
   esac
done

set -- "${ARGS[@]}"

[[ $refonly && $newonly ]] && {
   echo -n "both --ref and --new options set\n";
   exit 1;
}

[[ $refonly || $newonly ]] && nargs=1 || nargs=2
[ $dir ] && ((++nargs))
[ $# -ne $nargs ] && { echo -e "check number of arguments\n"; exit 1; }

[ $newonly ] && new=$1 || ref=$1
[[ ! $refonly ]] && { new=$2; shift; }
[ $dir ] && outdir=$2 || outdir=vfb-output

# check cms environment
if [[ -z $CMSSW_BASE || $(pwd)/ != $CMSSW_BASE/* ]]; then
   echo -e "current directory: $pwd does not match cmsenv: $CMSSW_BASE\n"
   exit 1
fi

pushd $CMSSW_BASE/src/

# check for uncommitted changes
if ! git diff-index --quiet HEAD; then
   echo -e "there are uncommitted changes\n"
   exit 1
fi

# produce forest files
[[ ! $newonly ]] && {
   mkdir -p $outdir/$ref/;
   run_configs $ref $outdir/$ref/;
}

[[ ! $refonly ]] && {
   mkdir -p $outdir/$new/;
   run_configs $new $outdir/$new/;
}

popd

echo -e "done!\n"
