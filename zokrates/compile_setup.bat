@echo off 
:: usage: compile_setup.bat <.zok filename>


zokrates compile -i %1/%1.zok -o %1/%1_bin -s %1/abi.json --stdlib-path ./stdlib &&^
zokrates setup -i %1/%1_bin -p %1/proving.key -v %1/verification.key
