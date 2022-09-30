#!/bin/sh

make -C certora munged-simple

certoraRun \
    certora/munged-simple/DLL.sol \
    --verify DLL:certora/specs/dll-simple.spec \
    --loop_iter 3 \
    --optimistic_loop \
    --send_only \
    --msg "Simple DLL verification" \
    --staging \
    $@
