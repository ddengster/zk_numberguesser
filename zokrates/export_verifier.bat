@echo off 

zokrates export-verifier -i %1/verification.key -o ../contracts/%1_verifier_temp.sol

