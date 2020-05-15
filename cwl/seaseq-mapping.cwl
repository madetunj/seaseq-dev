#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: Workflow

requirements:
  - class: ScatterFeatureRequirement
  - class: SubworkflowFeatureRequirement

inputs:
  bowtie_index: File
  fastqfile: File[]
  chromsizes: File
  blacklistfile: File
  best_alignments: boolean?
  good_alignments: int?
  limit_alignments: int?
  processors: int?

outputs:
  sam_sort:
    outputSource: SamSort/outfile
    type: File[]

  fastq_metrics:
    outputSource: BasicMetrics/metrics_out
    type: File[]

  rmdup_bam:
    outputSource: SamIndex/outfile
    type: File[]

  bklist_bam: 
    outputSource: BkIndex/outfile
    type: File[]

  bamqc_html:
    outputSource: BamQC/htmlfile
    type: File[]

  bamqc_zip:
    outputSource: BamQC/zipfile
    type: File[]

  readqc_zip:
    outputSource: ReadQC/zipfile
    type: File[]

  readqc_html:
    outputSource: ReadQC/htmlfile
    type: File[]

  stat_bk:
    outputSource: STATbk/outfile
    type: File[]

  stat_bam:
    outputSource: STATbam/outfile
    type: File[]

  stat_rmdup:
    outputSource: STATrmdup/outfile
    type: File[]


steps:
  BasicMetrics:
    requirements:
      ResourceRequirement:
        ramMax: 20000
        coresMin: 1
    in: 
      fastqfile: fastqfile
    out: [metrics_out]
    run: basicfastqstats.cwl
    scatter: fastqfile

  TagLen:
    in: 
      datafile: BasicMetrics/metrics_out
    out: [tagLength]
    run: taglength.cwl
    scatter: datafile
   
  ReadQC:
    in:
      infile: fastqfile
    out: [htmlfile, zipfile]
    run: fastqc.cwl
    scatter: infile

  Bowtie:
    requirements:
      ResourceRequirement:
        ramMax: 10000
        coresMin: 20
    run: bowtie.cwl
    in:
      readLengthFile: TagLen/tagLength
      best_alignments: best_alignments
      good_alignments: good_alignments
      fastqfile: fastqfile
      limit_alignments: limit_alignments
      processors: processors
      bowtie_index: bowtie_index
    out: [samfile]
    scatter: [readLengthFile, fastqfile]
    scatterMethod: dotproduct

  SamView:
    in:
      infile: Bowtie/samfile
    out: [outfile]
    run: samtools-view.cwl
    scatter: infile

  BamQC:
    in:
      infile: SamView/outfile
    out: [htmlfile, zipfile]
    run: fastqc.cwl
    scatter: infile

  SamSort:
    in:
      infile: SamView/outfile
    out: [outfile]
    run: samtools-sort.cwl
    scatter: infile

  BkList:
    in:
      infile: SamSort/outfile
      blacklistfile: blacklistfile
    out: [outfile]
    run: blacklist.cwl
    scatter: infile

  BkIndex:
    in:
      infile: BkList/outfile
    out: [outfile]
    run: samtools-index.cwl
    scatter: infile

  SamRMDup:
    in:
      infile: BkList/outfile
    out: [outfile]
    run: samtools-mkdupr.cwl
    scatter: infile

  SamIndex:
    in:
      infile: SamRMDup/outfile
    out: [outfile]
    run: samtools-index.cwl
    scatter: infile

  STATbam:
    in:
      infile: SamView/outfile
    out: [outfile]
    run: samtools-flagstat.cwl
    scatter: infile

  STATrmdup:
    in:
      infile: SamRMDup/outfile
    out: [outfile]
    run: samtools-flagstat.cwl
    scatter: infile

  STATbk:
    in:
      infile: BkList/outfile
    out: [outfile]
    run: samtools-flagstat.cwl
    scatter: infile


doc: |
  Runs ChIP-Seq SE Mapping FastQ SE files to generate BAM file for step 2 in ChIP-Seq Pipeline.
