#!/bin/sh

make -C certora munged-fifo

certoraRun \
    certora/munged-fifo/MockDLL.sol \
    --verify MockDLL:certora/specs/dll-fifo.spec \
    --loop_iter 4 \
    --optimistic_loop \
    --msg "FIFO DLL verification" \
    $@
