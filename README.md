
- `npm install @openzeppelin/contracts`

- `cd zokrates`

## Generating/using verifier code

### The zokrates general program flow:

1) Compile a program: `zokrates.exe compile -i initiate_game.zok -o initiate_game_bin --stdlib-path ./<path_to_stdlib>`, spits out an `initiate_game_bin` file

2) `zokrates setup -i initiate_game_bin`, spits out `proving.key` and `verification.key`

3) Compute a witness to your secret using the compiled `initiate_game_bin` program. Input your hidden value, and lower/upper range (eg. 5 is hidden number, ranged 1 to 10):
`zokrates compute-witness -i initiate_game_bin -o initiate_game_witness --verbose -a 5 1 10`. Outputs a `initiate_game_witness` file. Also outputs the return value of the function.

4) For checking, generate a `proof.json` via `zokrates generate-proof -i initiate_game_bin -w initiate_game_witness`, using `proving.key`, `out` and `witness` as input. Then `zokrates verify` to verify the generated `proof.json` using `verification.key`.

5) `zokrates export-verifier -o ../contracts/verifier.sol` to export solidity verifier code using `verification.key`. Before commiting data to your smart contract, call the `verifyTx` function with values from `proof.json` coupled with the range and hash and ensure the returned value is true.

### Workflow

- Do steps 1-3, but modify the code to return the hash instead. When computing the witness, 

Our solidity verifier code is put on the blockchain; treat it like an escrow that knows no actual secret values. It just knows a way verify all the things given to it

- 

# Guess the number via the blockchain!

- Initiator picks a number, and agree to a salt with the player(if you want to prevent rainbow attacks)

- Initiator starts a game with a hashed solution (?)

- Initiator sends 2 public numbers specifying a range and a proof for verification, ie. the 'Clue'. This proof is verified via smart contract before storing the values on the blockchain

- Players submit number guesses to the blockchain

- Initiator reads the number guesses, and submits either 'yay', 'higher' or 'lower' and a proof. The smart contract verifies it, and updates the game state.

- Claims an nft if sucessful

## GameDev Afterthoughts and Insights

- If your game needs 

- Your smart contract is your verifier of whatever the players send



# References:

- Devcon presentation, yt
https://docs.google.com/presentation/d/1gfB6WZMvM9mmDKofFibIgsyYShdf0RV_Y8TLz3k1Ls0/edit#slide=id.g443fe0d9f5_0_136

https://www.youtube.com/watch?v=_6TqUNVLChc

https://www.youtube.com/watch?v=YymE69JcKEk


- Sample code for presentation: https://github.com/leanthebean/puzzle-hunt

- Battleships paper https://courses.csail.mit.edu/6.857/2020/projects/13-Gupta-Kaashoek-Wang-Zhao.pdf

- https://github.com/matter-labs/awesome-zero-knowledge-proofs


The moment when you realize making zk-proofs from ranges is a harder problem than thought
- https://crypto.stackexchange.com/questions/53745/is-it-possible-to-create-a-zero-knowledge-proof-that-a-number-is-more-than-zero

- https://crypto.stackexchange.com/questions/42019/zero-knowledge-proof-for-sign-of-message-value/42029#42029

## Todos:

- uploading invalid games via initiate_game_bad and lopsided ranges

- determine gas costs

- deployment to any eth testnet blockchain
