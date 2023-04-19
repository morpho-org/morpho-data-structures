#!/bin/sh

make -C certora munged-simple

certoraRun \
    certora/munged-simple/MockDLL.sol \
    --verify MockDLL:certora/specs/dll-simple.spec \
    --loop_iter 7 \
    --optimistic_loop \
    --send_only \
    --msg "Simple DLL verification" \
    --staging \
    $@
