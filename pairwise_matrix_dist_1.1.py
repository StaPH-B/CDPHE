#!/usr/bin/env python
'''This script takes in a multisequence fasta and returns the hamming distances between all of the fasta seqs in the msf.
The sequences must be aligned in clustalw format.
Usage: pairwise_matrix_dist_1.1.py roary/core_gene_alignment.aln'''

import sys, os

def similarity(s1, s2):
    assert len(s1) == len(s2)
    try:
        if len(sys.argv[2]) >=0:
            return sum(ch1 != ch2 for ch1, ch2 in zip(s1, s2))
    except:
        return sum(ch1 != ch2 and ch1 != '-' and ch2 != '-' for ch1, ch2 in zip(s1, s2))
print "Running..."
fasta_dict = {}
hamming_dict = {}
ref_dict = {}
fasta_list = []
file = sys.argv[1]
f = open(file, 'r')
flines = f.readlines()
fasta_name = ''
print "........."
for line in flines:
    fasta_seq = line.strip('\n')
    if ">" in line:
        fasta_name = fasta_seq
        fasta_dict[fasta_name]= ''
    else:
        fasta_dict[fasta_name]+=fasta_seq
#print "Dictionary created"
for item in fasta_dict:
    fasta_list.append([item, str(fasta_dict[item]).upper()])
    #print str(item), len(str(fasta_dict[item]))
for i in range(len(fasta_list)):
    ref_dict[i] =  fasta_list[i][0]
    for j in range(len(fasta_list)):
        ref_dict[j]=fasta_list[j][0]
        if i<j:
            ham = similarity(fasta_list[i][1], fasta_list[j][1])
            hamming_dict[str(i)+','+str(j)] = str(ham)
g = open("hamming_output", "w")
for i in range(len(fasta_list)):
    for j in range(len(fasta_list)):
        if i>j:
            pass
            g.write('\t')
        if i==j:
            #print '0'
            g.write('0'+'\t')
        else:
            try:
                #print "("+str(i)+", "+str(j)+"):", hamming_dict[str(i)+','+str(j)],
                g.write(hamming_dict[str(i)+','+str(j)] + '\t')
            except:
                pass
    #print '\n'
    g.write('\n')

#print ref_dict
for item in ref_dict:
    g.write(str(ref_dict[item])+'\t')
f.close()
g.close()

#Create a file where the stair-step is a full matrix
matrix_dict = {}
line_len=''
z=open("hamming_output", "r")
zlines = z.readlines()
i=1
for line in zlines:
    if ">" in line:
        pass
    else:
        linesplit = line.split('\t')
        line_len = len(linesplit)
        j=i
        for item in linesplit:
            if item == '':
                pass
            else:
                matrix_dict[str(i)+', '+str(j)]=item
                if i != j:
                    matrix_dict[str(j)+', '+str(i)]=item
                j+=1
        i+=1
z.close()
h=open("pairwise_snp_matrix", "w")
matrix = []
for i in range(1, len(linesplit)):
    matrix_list = []
    for j in range(1, len(linesplit)):
        matrix_list.append(matrix_dict[str(i)+', '+str(j)])
    matrix.append(matrix_list)
for item in ref_dict:
    h.write(str(ref_dict[item]).replace(">", "")+'\t')
h.write('\n')
for item in matrix:
    for thing in item:
        h.write(str(thing)+'\t')
    h.write('\n')
h.close()
os.system("awk 'NR == 1 {for (i=1; i<=NF; i++) header[i]=$i} NR > 1 {for (i=1; i<=NF; i++) sum[i]+=$i;} END {for (i in sum) print header[i], (sum[i]/(NR-1))}' pairwise_snp_matrix |sort -n -k2 > avg_snp_differences_ordered")
dot='"."'
os.system("awk 'NR == 1 {for (i=1; i<=NF; i++) header[i+1]=$i} END {header[1]=" + str(dot) + "; for (i in header) print header[i]}' pairwise_snp_matrix > col1")
os.system("paste col1 pairwise_snp_matrix | column -s $'\t' -t > pairwise_snps")
os.system("rm col1")
os.system("mkdir snp_counts")
os.system("rm hamming_output")
os.system("mv pairwise_snps snp_counts")
os.system("rm pairwise_snp_matrix")
os.system("mv avg_snp_differences_ordered snp_counts")
print "Finished."
