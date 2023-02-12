#!/bin/sh

make -C certora munged-fifo

certoraRun \
    certora/munged-fifo/MockDLL.sol \
    --verify MockDLL:certora/specs/sanity.spec \
    --loop_iter 7 \
    --optimistic_loop \
    --send_only \
    --msg "FIFO DLL sanity" \
    $@
