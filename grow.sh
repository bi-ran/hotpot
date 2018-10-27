#!/bin/bash

helpmessage() {
   echo -e "usage: ./grow.sh [list] [config]\n"
   echo -e "   -h, --help     show (this) help message"
   echo -e "   -l, --logs     logs directory"
   echo -e "   -o, --output   output directory"
}

ARGS=()

while [ $# -gt 0 ]; do
   case "$1" in
      -h|--help)     helpmessage; exit 0 ;;
      -l|--logs)     log="$2"; shift 2 ;;
      --logs=*)      out="${1#*=}"; shift ;;
      -o|--output)   out="$2"; shift 2 ;;
      --output=*)    out="${1#*=}"; shift ;;
      -*)            echo -e "invalid option: $1\n"; exit 1 ;;
      *)             ARGS+=("$1"); shift ;;
   esac
done

set -- "${ARGS[@]}"

[ $# -ne 2 ] && { echo -e "check arguments\n"; exit 1; }

list=$1
config=$2

[ $out ] &&
   outdir=$(readlink -f $out) ||
   outdir=/eos/cms/store/group/phys_heavyions/rbi/persimmon/
[ $log ] &&
   logdir=$(readlink -f $log) ||
   logdir=/afs/cern.ch/work/r/rbi/private/logs/persimmon/

mkdir -p $outdir
mkdir -p $logdir

echo -e "  growing tree(s)..."
cat $list | while read line; do
   lesc=$(echo ${line%.*} | sed -e 's/\//_/g')
   cmsRun $config inputFiles=$line outputFile=$lesc.root &> $logdir/$lesc.log
done
