@echo off 
:: usage: compute_hash.bat <hidden secret>

zokrates compute-witness -i compute_hash/compute_hash_bin -o compute_hash/compute_hash_witness --verbose -a %1
