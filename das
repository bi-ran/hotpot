#!/bin/bash

helpmessage() {
   echo -e "usage: das [dataset] [...]\n"
   echo -e "   -g, --global   global dbs instance"
   echo -e "   -h, --help     show (this) help message"
}

ARGS=()

while [ $# -gt 0 ]; do
   case "$1" in
      -g|--global)   global=1; shift ;;
      -h|--help)     helpmessage; exit 0 ;;
      -*)            echo -e "invalid option: $1\n"; exit 1 ;;
      *)             ARGS+=("$1"); shift ;;
   esac
done

set -- "${ARGS[@]}"

[ $# -lt 1 ] && { echo -e "check arguments\n"; exit 1; }

instance=phys03
[ $global ] && instance=global

dasgoclient -query="$1 instance=prod/$instance ${@:2}"
