#!/usr/bin/env python3

from Bio import SeqIO
import argparse
import os
parser = argparse.ArgumentParser(
                    prog='extract_gbk',
                    description='Split gbk file into individual records',
                    )

parser.add_argument('-i','--input', help="input gbk file",required=True) # get the input gbkfile
parser.add_argument('-o','--output', help="output folder",required=True) # get the input gbkfile

args = parser.parse_args()

if not os.path.exists(args.output):
    os.mkdir(args.output)
    
for record in SeqIO.parse(args.input, "genbank"):
    id = record.id
    outfile = os.path.join(args.output,f'{id}.gbk')
    SeqIO.write(record, outfile, "genbank")
    