#!/bin/sh

make -C certora munged-simple

certoraRun \
    certora/munged-simple/DLL.sol \
    --verify DLL:certora/specs/sanity-simple.spec \
    --loop_iter 7 \
    --optimistic_loop \
    --send_only \
    --msg "Simple DLL sanity" \
    $@
