#!/bin/sh

make -C certora munged-simple

certoraRun \
    certora/munged-simple/MockDLL.sol \
    --verify MockDLL:certora/specs/sanity.spec \
    --loop_iter 7 \
    --optimistic_loop \
    --send_only \
    --msg "Simple DLL sanity" \
    $@
