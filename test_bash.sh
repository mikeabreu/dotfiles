#!/usr/bin/env bash
this_file=$(basename $0)
echo "First Test";[[ -f $this_file ]] && \
    echo "Successful Echo"; \
    echo "Continuation Test";[[ -f $base_file ]] && \
        echo "False Echo"
echo "Final Echo"

TEST="True"
TESTVAR=${TEST:-"False"}
echo $TESTVAR