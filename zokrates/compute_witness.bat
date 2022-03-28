@echo off 
:: usage: compute_witness.bat <.zok filename> <hidden_val> <hash> <lowerrange> <upperrange>

zokrates compute-witness -i %1_bin -o %1_witness --verbose -a %2 %3 %4 %5 &&^
zokrates generate-proof -i %1_bin -w %1_witness &&^
zokrates verify