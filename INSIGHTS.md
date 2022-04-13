
# Bunch of insights gained while developing this game. May/may not be true!

11th April 2022

## 1) Javascript(JS) has different subsets of functionality/code.

- 'Browser' javascript, aka CommonJS(?), is JS that runs in the browser. There are limitations in that you can't read/run files without user input, so you have to setup a local server for that

- 'NodeJS' javascript, meant for servers and general purpose programming

## 2) A lot of code in stackexchange javascript posts are usually presented as the asynchronous type. This can turn out to be really annoying for code.

## 3) Solidity incentivizes bad inheritance paradigms because instantiation of contracts costs extra gas than inheritance. It's a pity it has to be this way. Maybe c-style 'static functions' could be introduced as alternative?

## 4) Exporting multiple Zokrates-generated contracts: these, including functions need to be renamed since inheritance.

# Worth investigating

1) A way to do the ganache ui steps via command line