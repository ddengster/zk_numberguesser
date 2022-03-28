@echo off 
:: usage: compute_hash.bat <hidden secret>

zokrates compile -i compute_hash.zok -o compute_hash --stdlib-path ./stdlib &&^
zokrates compute-witness -i compute_hash -o compute_hash_witness --verbose -a %1
