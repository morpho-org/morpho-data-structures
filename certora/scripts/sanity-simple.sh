#!/bin/sh

make -C certora munged-simple

certoraRun \
    certora/munged-simple/MockDLL.sol \
    --verify MockDLL:certora/specs/sanity.spec \
    --loop_iter 7 \
    --optimistic_loop \
    --msg "Simple DLL sanity" \
    $@
