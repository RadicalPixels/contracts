#! /bin/bash

RADICAL_PIXELS=RadicalPixels.sol

OUTPUT=flattened

npx truffle-flattener contracts/$RADICAL_PIXELS > $OUTPUT/$RADICAL_PIXELS
