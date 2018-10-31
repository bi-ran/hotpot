#!/bin/bash

helpmessage() {
   echo -e "usage: ./till.sh [skip] [config]\n"
   echo -e "   -g, --grow     grow trees directly"
   echo -e "   -h, --help     show (this) help message"
   echo -e "   -l, --logs     logs directory"
   echo -e "   -o, --output   output directory"
   echo -e "   -s, --stream   data streamer"
}

ARGS=()

while [ $# -gt 0 ]; do
   case "$1" in
      -g|--grow)     grow=1; shift ;;
      -h|--help)     helpmessage; exit 0 ;;
      -l|--logs)     log="$2"; shift 2 ;;
      --logs=*)      out="${1#*=}"; shift ;;
      -o|--output)   out="$2"; shift 2 ;;
      --output=*)    out="${1#*=}"; shift ;;
      -s|--stream)   stream="$2"; shift 2 ;;
      --stream=*)    stream="${1#*=}"; shift ;;
      -*)            echo -e "invalid option: $1\n"; exit 1 ;;
      *)             ARGS+=("$1"); shift ;;
   esac
done

set -- "${ARGS[@]}"

[ $# -lt 1 ] || [ $# -gt 2 ] && {
   echo -e "check arguments\n"; exit 1; }
[ $grow ] && [ $# -lt 2 ] && {
   echo -e "no config specified for --grow\n"; exit 1; }

skip=$1; shift

[ $out ] &&
   outdir=$(readlink -f $out) ||
   outdir=/eos/cms/store/group/phys_heavyions/rbi/persimmon/
[ $log ] &&
   logdir=$(readlink -f $log) ||
   logdir=/afs/cern.ch/work/r/rbi/private/logs/persimmon/
[ $stream ] || stream=HIPhysicsMinimumBiasReducedFormat8

data=/eos/cms/store/t0streamer/Data/$stream/000

for high in $(ls $data); do
   for low in $(ls $data/$high); do
      run=$high$low
      if ! grep -Fqx "$run" $skip; then
         files=($data/$high/$low/*)
         mkdir -p $logdir/$run/
         for i in {1...4}; do
            echo ${files[$RANDOM % ${#files[@]}]} \
               >> $logdir/$run/till_${stream}_$run.list
         done

         echo -ne "\033[34m"
         echo -n "./grow.sh -l $logdir/$run/ -o $outdir/$run/ "
         echo -n "$logdir/$run/till_${stream}_$run.list "
         echo -n "$@"
         echo -e "\033[0m"

         [ $grow ] &&
            grow.sh -l $logdir/$run/ -o $outdir/$run/ \
               $logdir/$run/till_${stream}_$run.list $@
      fi
   done
done