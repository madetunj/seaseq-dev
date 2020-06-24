#!/usr/bin/env cwl-runner
cwlVersion: v1.0
baseCommand: [ bedtools, getfasta ]
class: CommandLineTool

hints:
  DockerRequirement:
    dockerPull: madetunj/bedtools:v2.25.0

doc: |
  bedtools getfasta -fi <reference fa> -bed <peads bed> -fo <fasta outputfile>


requirements:
- class: ShellCommandRequirement
- class: InlineJavascriptRequirement

  expressionLib:
  - var var_output_name = function() {
      if (inputs.bedfile != null) {
         return inputs.bedfile.nameroot+'.fa';
      }
   };

- class: InitialWorkDirRequirement
  listing: [ $(inputs.ref_fasta), $(inputs.ref_fasta_index) ]

inputs:
  ref_fasta:
    type: File?
    inputBinding:
      prefix: -fi
      position: 1

  ref_fasta_index:
    type: File?

  bedfile:
    type: File
    label: "BED file"
    inputBinding:
      position: 2
      prefix: -bed
  
  outputfile:
    type: string
    label: "Output FASTA file name"
    inputBinding:
      position: 3
      prefix: -fo
      valueFrom: |
        ${
            if (self == ""){
              return var_output_name();
            } else {
              return self;
            }
        }
    default: ""

outputs:
  outfile:
    type: File
    label: "Output FASTA"
    outputBinding:
      glob: |
        ${
          if (inputs.outputfile == "") {
            return var_output_name();
          } else {
            return inputs.outputfile;
          }
        }
