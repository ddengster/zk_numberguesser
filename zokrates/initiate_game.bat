@echo off 
:: usage: initiate_game.bat initiate_game <hidden_val> <hash> <lowerrange> <upperrange>

zokrates compute-witness -i %1/%1_bin -o %1/%1_witness --verbose -a %2 %3 %4 %5 &&^
zokrates generate-proof -i %1/%1_bin -w %1/%1_witness -j %1/proof.json -p %1/proving.key &&^
zokrates verify -j %1/proof.json -v %1/verification.key
