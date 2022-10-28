#!/bin/sh

make -C certora munged-fifo

certoraRun \
    certora/munged-fifo/DLL.sol \
    --verify DLL:certora/specs/dll-fifo.spec \
    --loop_iter 4 \
    --optimistic_loop \
    --send_only \
    --msg "FIFO DLL verification" \
    --staging \
    $@
