#!/bin/bash

helpmessage() {
   echo -e "usage: das [dataset] [...]\n"
   echo -e "   -f, --forward  forward arguments to dasgoclient"
   echo -e "   -g, --global   global dbs instance"
   echo -e "   -h, --help     show (this) help message"
   echo -e "   -l, --link     generate das web link"
}

ARGS=()

while [ $# -gt 0 ]; do
   case "$1" in
      -f|--forward)  fwargs="$2"; shift 2 ;;
      --forward=*)   fwargs="${1#*=}"; shift ;;
      -g|--global)   global=1; shift ;;
      -h|--help)     helpmessage; exit 0 ;;
      -l|--link)     link=1; shift ;;
      -*)            echo -e "invalid option: $1\n"; exit 1 ;;
      *)             ARGS+=("$1"); shift ;;
   esac
done

set -- "${ARGS[@]}"

[ $# -lt 1 ] && { echo -e "check arguments\n"; exit 1; }

dataset=$1

instance=phys03
[ $global ] && instance=global

echo
resp=$(dasgoclient $fwargs -query="$dataset instance=prod/$instance ${@:2}")

[ "$resp" ] && echo -e "$resp" || {
   echo -e "  null response"
   exit 1
}

[ $link ] && {
   url='https://cmsweb.cern.ch/das/request?input=dataset='
   echo -e "\n$url$dataset&instance=prod/$instance"
}
