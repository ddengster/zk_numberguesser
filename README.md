
# Zero Knowledge Number Guessing

A number guessing game on the ethereum blockchain using Zokrates.

## How it works

- Initiator starts a game with a secret number

- Initiator run a program with the secret number, it's hash, and 2 additional numbers specifying a range. The program, after verification/checking, spits out commits a proof of the computation. This proof is verified via smart contract before storing the values on the blockchain.

- Players submit number guesses to the blockchain

- Initiator reads the number guesses, and submits either 'yay', 'higher' or 'lower' and a proof of that computation. The smart contract verifies it, and updates the game state. This is repeated until the guess is correct.

- Players may claim an nft if successful

## Requirements & installation

- GO compiler, version 1.18 windows/amd64

- Download the windows version of Zokrates from https://github.com/Zokrates/ZoKrates/releases and unzip it into the `zokrates` folder. Make sure the `stdlib` folder is there

- Truffle, a blockchain testing suite from https://trufflesuite.com/docs/truffle/getting-started/installation/

- Ganache, personal development blockchain https://trufflesuite.com/docs/ganache/quickstart/

- `git clone` this repository and run `npm install`

## Running

- Setup and compile the zokrates programs. `cd zokrates` and run 

```
compile_setup.bat compute_hash
compile_setup.bat initiate_game
compile_setup.bat eval_guess
```

- Run the local backend server in one terminal via `cd backend && go run zokrates_server.go`

- Run ganache -> `QuickStart`, then click on the `Settings` gear and link `truffle-config.js` under the workspace tab, then hit `Save and Restart`

- Within ganache under the accounts tab, copy 2 addresses and paste them in `frontend/app.js` like so

```
const contract_addr = ...;
const player1Addr = "<ganache account address #1>";
const player2Addr = "<ganache account address #2>";
```

- Run truffle migrate and copy the contract address of 'GuessTheNumberGameLayer' and paste it into `frontend/app.js` like so

```
const contract_addr = "<your contract address here>";
const player1Addr = ...;
const player2Addr = ...;
```

- Launch `frontend/index.html`, execute the steps left to right.

- Or `truffle test` to run tests.

## Generating/using verifier code

### The zokrates general program flow:

1) To get started, you'll have to compile and setup the programs. `zokrates compile` spits out a `_bin` binary and `abi.json`, while `zokrates setup` spits out `proving.key` and `verification.key`

2) From then on you may decide to export a solidity verifier or compute a witness using the binary.

3) If exporting the verifier, `zokrates export-verifier-i verification.key -o ../contracts/verifier.sol` takes in the generated verification key from the `setup` step and outputs . You'll then have to integrate it into your contract code.

4) If computing a witness, `zokrates compute-witness` uses the binary to output a witness file. Then `zokrates generate-proof` uses the binary, the `witness` file, and the `proving.key` to output `proof.json`. You can then use that json as input to your generated solidity contract or use `zokrates verify` that takes the `proof.json` and the `verification.key` from step 1 to verify if the proof is generated correctly.

# References:

- Devcon presentation, yt
https://docs.google.com/presentation/d/1gfB6WZMvM9mmDKofFibIgsyYShdf0RV_Y8TLz3k1Ls0/edit#slide=id.g443fe0d9f5_0_136

https://www.youtube.com/watch?v=_6TqUNVLChc

https://www.youtube.com/watch?v=YymE69JcKEk


- Sample code for presentation: https://github.com/leanthebean/puzzle-hunt

- https://github.com/matter-labs/awesome-zero-knowledge-proofs


## Future Todos:

- deployment to any eth testnet blockchain

- supplement the hash of the secret number with salt(via key strengthening/key stretching)