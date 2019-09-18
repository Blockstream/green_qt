#!/bin/bash
set -eo pipefail


dotter() {
    while :
    do
        sleep 30
        echo -n .
    done
}

echo


dotter&
