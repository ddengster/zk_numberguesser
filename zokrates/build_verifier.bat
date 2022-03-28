@echo off 
:: usage: build_verifier.bat <.zok filename>


zokrates compile -i %1.zok -o %1_bin --stdlib-path ./stdlib &&^
zokrates inspect -i %1_bin &&^
zokrates setup -i %1_bin &&^
zokrates export-verifier -o ../contracts/%1_verifier.sol

