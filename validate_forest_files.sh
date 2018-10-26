#!/bin/bash

ARGS=()

while [ $# -gt 0 ]; do
   case "$1" in
      -o|--out)      out="$2"; shift 2 ;;
      --out=*)       out="${1#*=}"; shift ;;
      -v|--val)      val="$2"; shift 2 ;;
      --val=*)       val="${1#*=}"; shift ;;
      -*|--*)        echo -e "invalid option: $1\n"; exit 1 ;;
      *)             ARGS+=("$1"); shift ;;
   esac
done

set -- "${ARGS[@]}"

[ $# -lt 1 ] && { echo -e "check arguments\n"; exit 1; }

[ $val ] &&
   valdir=$(readlink -f $val) ||
   valdir=/afs/cern.ch/user/r/rbi/cmssw/CMSSW_10_3_0/src/ForestValidation

input=$(readlink -f $1); shift
tag=$1; [ -z "$tag" ] && tag=vff; shift

[ $out ] &&
   outdir=$(readlink -f $out) ||
   outdir=$(pwd)/vff-output
mkdir -p $outdir

firstdir=$input/$(ls $input -1 | head -1)
files=$(ls $firstdir/*.root)

# navigate to forest validation directory
pushd $valdir &> /dev/null
eval `scramv1 runtime -sh`
make -j8

for d in $(ls $input/* -d); do
   argl=$argl,$(basename $d)
done
argl="${argl:1}"
brtag=$(echo "$argl" | tr ',' '_')

for f in ${files[@]}; do
   argf=
   for d in $(ls $input/* -d); do
      argf=$argf,$d/$(basename $f)
   done
   argf="${argf:1}"

   filetag=$tag-$(basename $f .root)
   fulltag=${filetag}_${brtag}

   date=$(date +"%Y%m%d")
   ./bin/runForestDQM.exe $argf $filetag $argl "$@" &> $outdir/rfd-$fulltag.log

   dir=pdfDir/$date/forestDQM_${fulltag}_${date}
   base=forestDQM_${fulltag}_${date}VALIDATION_MAIN_AllTrees_${date}

   pushd $dir &> /dev/null
   echo -n "  compiling pdf..."
   pdflatex $base.tex &> $outdir/tex-$base.log
   echo " $(readlink -f $base.pdf)"
   popd &> /dev/null
done

echo -e "\n  done!"
