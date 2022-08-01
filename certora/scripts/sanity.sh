#!/bin/sh

make -C certora munged

certoraRun \
    certora/munged/DoubleLinkedList.sol \
    --verify DoubleLinkedList:certora/specs/sanity.spec \
    --loop_iter 3 \
    --optimistic_loop \
    --send_only \
    --msg "Sanity" \
    $@
