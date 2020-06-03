#!/usr/bin/env cwl-runner
cwlVersion: v1.0
baseCommand: [samtools, markdup, -r]
class: CommandLineTool
label: mark and remove duplicates from bam file

requirements:
- class: ShellCommandRequirement
- class: InlineJavascriptRequirement

  expressionLib:
  - var var_output_name = function() {
      if (inputs.infile != null) {
         return inputs.infile.nameroot.split('.bam')[0]+'.rmdup.bam';
      }
   };

inputs:
  infile:
    type: File
    label: "BAM file"
    inputBinding:
      prefix: '-s'
      position: 1

  outputfile:
    type: string?
    label: "Output file name"
    inputBinding:
      position: 2
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
    label: "Remove duplicates BAM output file"
    outputBinding:
      glob: |
        ${
          if (inputs.outputfile == "") {
            return var_output_name();
          } else {
            return inputs.outputfile;
          } 
        }
