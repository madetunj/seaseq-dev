#!/bin/bash

tmp="$(pwd)/tmpdir"
out="$(pwd)/outdir"

#mkdir -p $tmp $out

cwltool \
--parallel \
--preserve-entire-environment \
--copy-outputs \
--outdir $out \
../cwl/dev-seaseq_pipeline.cwl inputyml.yml
