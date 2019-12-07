#!/bin/bash

for dir in day*/; do
    pushd $dir
    nimble build
    popd
done
