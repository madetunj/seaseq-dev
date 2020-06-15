#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: Workflow

requirements:
  - class: ScatterFeatureRequirement
  - class: SubworkflowFeatureRequirement

inputs:
  reference: Directory?

  #individual indexes
  bowtieindex_1: File?
  bowtieindex_2: File?
  bowtieindex_3: File?
  bowtieindex_4: File?
  bowtieindex_rev_1: File?
  bowtieindex_rev_2: File?
  ref_fasta: File?
  ref_fasta_index: File?


  gtffile: File
  fastqfile: File[]
  chromsizes: File
  blacklistfile: File
  motifdatabases: File[]

  best_alignments: boolean?
  good_alignments: int?
  limit_alignments: int?
  processors: int?

  # MACS
  nomodel: boolean?
  wiggle: boolean?
  single_profile: boolean?
  shiftsize: int?
  space: int?
  pvalue: string?
  keep_dup: string?
  flank: int?

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

# MACS-AUTO
  macsDir:
    type: Directory[]
    outputSource: MACS-Auto/macsDir

# MOTIFs & Summits output
  bedfasta:
    type: File[]
    outputSource: MOTIFS/bedfasta

  memechipdir:
    type: Directory[]
    outputSource: MOTIFS/memechipdir

  amedir:
    type: Directory[]
    outputSource: MOTIFS/amedir

steps:
  BasicMetrics:
    requirements:
      ResourceRequirement:
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
        coresMin: 2
    run: bowtie.cwl
    in:
      readLengthFile: TagLen/tagLength
      best_alignments: best_alignments
      good_alignments: good_alignments
      fastqfile: fastqfile
      limit_alignments: limit_alignments
      processors: processors
      reference: reference
      bowtieindex_1: bowtieindex_1
      bowtieindex_2: bowtieindex_2
      bowtieindex_3: bowtieindex_3
      bowtieindex_4: bowtieindex_4
      bowtieindex_rev_1: bowtieindex_rev_1
      bowtieindex_rev_2: bowtieindex_rev_2
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

# PEAK CALLING & VISUALS
  MACS-Auto:
    requirements:
      ResourceRequirement:
        coresMin: 1
    in:
      treatmentfile: BkIndex/outfile
      space: space
      pvalue: pvalue
      wiggle: wiggle
      single_profile: single_profile
    out: [ peaksbedfile, peaksxlsfile, summitsfile, wigfile, macsDir ]
    run: macs1call.cwl
    scatter: treatmentfile

# MOTIF analysis
  MOTIFS:
    in:
      reference: reference
      ref_fasta: ref_fasta
      ref_fasta_index: ref_fasta_index
      bedfile: MACS-Auto/peaksbedfile
      motifdatabases: motifdatabases
    out: [memechipdir, amedir, bedfasta]
    run: motifs.cwl
    scatter: bedfile
