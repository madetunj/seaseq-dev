#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: Workflow
doc: |
  - seaseq_pipeline.cwl is a complete analysis pipeline for CHiP 
      sequencing single-end data.
  - analysis pipeline includes mapping using bowtie, peak-calls 
      using MACS1 and SICER, motif analysis using meme suite, 
      enhancers & super-enhancers using ROSE, bam density plots 
      using BAM2GFF.

requirements:
  - class: SubworkflowFeatureRequirement
  - class: ScatterFeatureRequirement

inputs:
# main files & directorys
  reference: Directory
  gtffile: File
  fastqfile: File[]
  chromsizes: File
  blacklistfile: File
  motifdatabases: File[]

# optional parameters
  #BOWTIE
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
  
  # SICER & ROSE
  species: string?
  
  # SICER
  redundancy: int?
  window: int?
  fragment_size: int?
  genome_fraction: double?
  gapsize: int?
  evalue: int?

  # ROSE
  feature: string?

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
 
# MACS-AUTO
  macsDir:
    type: Directory[]
    outputSource: MACS-Auto/macsDir

# MACS-ALL
  allmacsDir:
    type: Directory[]
    outputSource: MACS-All/macsDir

# MACS-NM
  nmmacsDir:
    type: Directory[]
    outputSource: MACS-NM/macsDir

#VISUAL
  rpmwig:
    type: File[]
    outputSource: WIG-Auto/rpmwig

  outBW:
    outputSource: WIG-Auto/outBW
    type: File[]

  outtdf:
    outputSource: WIG-Auto/outtdf
    type: File[]

  allrpmwig:
    type: File[]
    outputSource: WIG-All/rpmwig

  alloutBW:
    outputSource: WIG-All/outBW
    type: File[]

  allouttdf:
    outputSource: WIG-All/outtdf
    type: File[]

  nmrpmwig:
    type: File[]
    outputSource: WIG-NM/rpmwig

  nmoutBW:
    outputSource: WIG-NM/outBW
    type: File[]

  nmouttdf:
    outputSource: WIG-NM/outtdf
    type: File[]

# MOTIFs & Summits output
  bedfasta:
    type: File[]
    outputSource: MOTIFS/bedfasta

  flankbed:
    type: File[]
    outputSource: FlankBED/outfile
    
  memechipdir:
    type: Directory[]
    outputSource: MOTIFS/memechipdir

  summitmemechipdir:
    type: Directory[]
    outputSource: SummitMOTIFS/memechipdir

  amedir:
    type: Directory[]
    outputSource: MOTIFS/amedir

  summitamedir:
    type: Directory[]
    outputSource: SummitMOTIFS/amedir
    
# METAGENE output
  metagenesDir:
    type: Directory[]
    outputSource: MetaGene/metagenesDir

# SICER output
  sicerDir:
    type: Directory[]
    outputSource: SICER/sicerDir

# ROSE output
  roseoutput:
    type: Directory[]
    outputSource: ROSE/RoseDir

# QC Control & Statistics output
  statsfile:
    type: File[]
    outputSource: PeaksQC/statsfile

  htmlfile:
    type: File[]
    outputSource: PeaksQC/htmlfile
    
  textfile:
    type: File[]
    outputSource: PeaksQC/textfile

steps:
  BasicMetrics:
    requirements:
      ResourceRequirement:
        #ramMax: 20000
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
        #ramMax: 10000
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
        #ramMax: 10000
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

  WIG-Auto:
    in:
      wigfile: MACS-Auto/wigfile
      peaksxls: MACS-Auto/peaksxlsfile
      chromsizes: chromsizes
    out: [ rpmwig, outBW, outtdf ]
    run: visualization.cwl
    scatter: [wigfile, peaksxls]
    scatterMethod: dotproduct

  MACS-All:
    requirements:
      ResourceRequirement:
        #ramMax: 10000
        coresMin: 1
    in:
      treatmentfile: BkIndex/outfile
      keep_dup: keep_dup
      space: space
      pvalue: pvalue
      wiggle: wiggle
      single_profile: single_profile
    out: [ peaksbedfile, peaksxlsfile, summitsfile, wigfile, macsDir ]
    run: macs1call.cwl
    scatter: treatmentfile

  WIG-All:
    in:
      wigfile: MACS-All/wigfile
      peaksxls: MACS-All/peaksxlsfile
      chromsizes: chromsizes
    out: [ rpmwig, outBW, outtdf ]
    run: visualization.cwl
    scatter: [wigfile, peaksxls]
    scatterMethod: dotproduct

  MACS-NM:
    requirements:
      ResourceRequirement:
        #ramMax: 10000
        coresMin: 1
    in:
      treatmentfile: BkIndex/outfile
      space: space
      wiggle: wiggle
      single_profile: single_profile
    out: [ peaksbedfile, peaksxlsfile, summitsfile, wigfile, macsDir ]
    run: macs1nm.cwl
    scatter: treatmentfile

  WIG-NM:
    in:
      wigfile: MACS-NM/wigfile
      peaksxls: MACS-NM/peaksxlsfile
      chromsizes: chromsizes
    out: [ rpmwig, outBW, outtdf ]
    run: visualization.cwl
    scatter: [wigfile, peaksxls]
    scatterMethod: dotproduct

# MOTIF analysis
  MOTIFS:
    in:
      reference: reference
      bedfile: MACS-Auto/peaksbedfile
      motifdatabases: motifdatabases
    out: [memechipdir, amedir, bedfasta]
    run: motifs.cwl
    scatter: bedfile

#SUMMIT-MOTIF analysis
  FlankBED:
    in:
      bedfile: MACS-Auto/summitsfile
      flank: flank
    out: [outfile]
    run: flankbed.cwl
    scatter: bedfile
  
  SummitMOTIFS:
    in:
      reference: reference
      bedfile: FlankBED/outfile
      motifdatabases: motifdatabases
    out: [memechipdir, amedir, bedfasta]
    run: motifs.cwl
    scatter: bedfile
    
# METAGENE analysis
  MetaGene:
    in:
      bamfile: SamIndex/outfile
      gtffile: gtffile
      chromsizes: chromsizes
    out:  [ metagenesDir ] 
    run: bamtogff.cwl
    scatter: bamfile

# SICER broad peaks caller
  B2Bed:
    in:
      infile: SamIndex/outfile
    out: [ outfile ]
    run: bamtobed.cwl
    scatter: infile

  SICER:
    requirements:
      ResourceRequirement:
        #ramMax: 10000
        coresMin: 1
    in:
      species: species
      redundancy: redundancy
      window: window
      fragment_size: fragment_size
      genome_fraction: genome_fraction
      gapsize: gapsize
      evalue: evalue
      treatmentbedfile: B2Bed/outfile
    run: sicer.cwl
    out: [ sicerDir ]
    scatter: treatmentbedfile

# ROSE enhancer caller
  ROSE:
    requirements:
      ResourceRequirement:
        #ramMax: 20000
        coresMin: 1
    in:
      species: species
      feature: feature
      gtffile: gtffile
      bamfile: BkIndex/outfile
      fileA: MACS-All/peaksbedfile
      fileB: MACS-Auto/peaksbedfile
    out: [ RoseDir ]
    run: roseNC.cwl
    scatter: [bamfile, fileA, fileB]
    scatterMethod: dotproduct

# Quality Control & Statistics
  Bklist2Bed:
    in:
      infile: BkIndex/outfile
    out: [ outfile ]
    run: bamtobed.cwl
    scatter: infile

  SortBed:
    requirements:
      ResourceRequirement:
        #ramMax: 10000
        coresMin: 1
    in:
      infile: Bklist2Bed/outfile
    out: [outfile]
    run: sortbed.cwl
    scatter: infile

  runSPP:
    requirements:
      ResourceRequirement:
        #ramMax: 10000
        coresMin: 1
    in:
      infile: BkIndex/outfile
    out: [spp_out]
    run: runSPP.cwl
    scatter: infile

  CountIntersectBed:
    requirements:
      ResourceRequirement:
        #ramMax: 10000
        coresMin: 1
    in:
      peaksbed: MACS-Auto/peaksbedfile
      bamtobed: SortBed/outfile
    out: [outfile]
    run: intersectbed.cwl
    scatter: [peaksbed, bamtobed]
    scatterMethod: dotproduct

  PeaksQC:
    requirements:
      ResourceRequirement:
        #ramMax: 10000
        coresMin: 1
    in:
      fastqmetrics: BasicMetrics/metrics_out
      fastqczip: ReadQC/zipfile
      sppfile: runSPP/spp_out
      bambed: Bklist2Bed/outfile
      countsfile: CountIntersectBed/outfile
      peaksxls: MACS-Auto/peaksxlsfile
      bamflag: STATbam/outfile
      rmdupflag: STATrmdup/outfile
      bkflag: STATbk/outfile
      rosedir: ROSE/RoseDir
    out: [ statsfile, htmlfile, textfile ]
    run: summarystats.cwl
    scatter: [fastqmetrics, fastqczip, sppfile, bambed, countsfile, peaksxls, bamflag, rmdupflag, bkflag, rosedir]
    scatterMethod: dotproduct
