#!/usr/bin/env cwl-runner
cwlVersion: v1.0
baseCommand: bowtie
class: CommandLineTool

hints:
  DockerRequirement:
    dockerPull: madetunj/bowtie:v1.2.3

#INITIAL SYNTAX
label: Bowtie on ChipSeq reads
doc: |
  bsub -K -R \"rusage[mem=10000]\" -n 20 -q standard -R \"select[rhel7]\" bowtie -l \$readLength -p 20 -k 2 -m 2 --best -S /datasets/public/genomes/Homo_sapiens/hg19/TOPHAT/hg19 ${files[$file]} \> $file.sam" >> $outfile


requirements:
- class: ShellCommandRequirement
- class: InlineJavascriptRequirement

  expressionLib:
  - var var_output_name = function() {
      if (inputs.output_prefix != null) { return inputs.output_prefix+'.sam'; } 
      else if (inputs.fastqfile.basename.split('_').length < 2) { return inputs.fastqfile.basename.split('.fastq').slice(0,-1)+'.sam'; }
      else { return inputs.fastqfile.basename.split('_').slice(0,-2).join('_')+'.sam'; }
   };
  - var var_readLength = function() {
      if (inputs.readLengthFile != null) {
        return inputs.readLengthFile.nameroot;
      }
   };
  - var var_indexName = function() {
      if (inputs.bowtieindex_rev_1 != null) {
        return inputs.bowtieindex_rev_1.path.split('.rev').slice(0,-1);
      }
   };
   
- class: InitialWorkDirRequirement
  listing: [ $(inputs.bowtieindex_rev_1),
            $(inputs.bowtieindex_rev_2),
            $(inputs.bowtieindex_1),
            $(inputs.bowtieindex_2),
            $(inputs.bowtieindex_3),
            $(inputs.bowtieindex_4),
          ]
inputs:
  output_prefix:
    type: string?
    label: "Output prefix name"

  processors:
    type: int?
    label: "number of alignment threads"
    default: 20
    inputBinding:
      prefix: -p
      position: 1

  good_alignments:
    type: int?
    label: "minimum good alignments per read"
    default: 2
    inputBinding:
      prefix: -k
      position: 2

  limit_alignments:
    type: int?
    label: "maximum number of alignemnts"
    default: 2
    inputBinding:
      prefix: -m
      position: 3

  readLength:
    type: int
    label: "read length"
    inputBinding:
      prefix: -l
      position: 4
      valueFrom: |
        ${
            if (self == 0){
              return var_readLength();
            } else {
              return self;
            }
         }
    default: 0

  readLengthFile:
    type: File?
    label: "read length"

  best_alignments:
    type: boolean?
    label: "guaranteed best hits"
    default: true
    inputBinding:
      prefix: --best
      position: 5

  bowtieindex_1:
    type: File?

  bowtieindex_2:
    type: File?
        
  bowtieindex_3:
    type: File?
        
  bowtieindex_4:
    type: File?
    
  bowtieindex_rev_1:
    type: File?
    inputBinding:
      position: 6
      valueFrom: |
        ${
            return var_indexName();
        }
      
  bowtieindex_rev_2:
    type: File?
  
  fastqfile:
    type: File
    label: "FastQ file"
    inputBinding:
      position: 7

  samoutput:
    type: boolean?
    label: "write hits in SAM format"
    default: true
    inputBinding:
      prefix: -S
      position: 8

  samfilename:
    type: string?
    label: "SAM file name"
    default: ""

stdout: |
  ${
    if (inputs.samfilename == "") {
      return var_output_name();
    } else {
      return inputs.samfile;
    }
  }

outputs:
  samfile:
    type: stdout
    label: "output file"

