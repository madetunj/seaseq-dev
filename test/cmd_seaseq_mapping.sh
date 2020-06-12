seaseqworkflow="../cwl/seaseq-mapping.cwl"
out="$(pwd)/seaseq-outdir"
tmp="$(pwd)/seaseq-tmpdir"
jobstore="seaseq-jobstore"
logtxt="seaseq-log.txt"
logout="seaseq-log_out"
logerr="seaseq-log_err"
inputyml="inputyml.yml"

cwltool \
$seaseqworkflow $inputyml 
#1>$logout 2>$logerr
