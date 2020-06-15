#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: Workflow

requirements:
  - class: StepInputExpressionRequirement
  - class: InlineJavascriptRequirement

inputs: 
  reference:
    type: Directory?
    label: "Genome reference directory"

  ref_fasta:
    type: File?

  ref_fasta_index:
    type: File?

  bedfile:
    type: File
    label: "peaks bed file"

  motifdatabases:
    type:  File[]
    label: "MEME motif databases to identify motif enrichment"


outputs:
  memechipdir:
    type: Directory
    outputSource: MEMECHIP/outDir
    label: "MEMECHIP output directory"

  amedir:
    type: Directory
    outputSource: AME/outDir
    label: "AME output directory"
 
  bedfasta:
    type: File
    outputSource: BEDfasta/outfile
    label: "BED converted FASTA file"
    

steps:  
  MEMECHIP:
    run: meme-chip.cwl
    in:
      convertfasta: BEDfasta/outfile
    out: [outDir]

  AME:
    requirements:
      ResourceRequirement:
        coresMin: 1
    run: ame.cwl
    in:
      convertfasta: BEDfasta/outfile
      motifdatabases: motifdatabases
    out: [outDir]

  BEDfasta:
    in:
      reference: reference
      ref_fasta: ref_fasta
      ref_fasta_index: ref_fasta_index
      bedfile: bedfile
    out: [outfile]
    run: bedfasta.cwl


doc: |
  Workflow calls MOTIFS both enriched and discovered using the MEME-suite (AME & MEME-chip).
