#!/bin/sh

make -C certora munged

certoraRun \
    certora/munged/DLL.sol \
    --verify DLL:certora/specs/sanity.spec \
    --loop_iter 3 \
    --optimistic_loop \
    --send_only \
    --msg "Simple DLL sanity" \
    $@
