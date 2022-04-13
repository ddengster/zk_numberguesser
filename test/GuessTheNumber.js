
const GuessTheNumberGameLayer = artifacts.require("GuessTheNumberGameLayer");
const BigNumber = require('bignumber.js');

contract("GuessTheNumberGameLayer", (accounts)=> {

  // initiate_game.bat initiate_game 3 8317554905031743436470060412079836410388093405773061122028896578523632029169 1 5
  let proof = {
    "proof": {
      "a": [
        "0x2b9f04515548c60b2d5f713c9d046f172b0d67e3df5fe4847cf479f0a8818bbe",
        "0x29c1c9091f618a5e25eb5400e6c70c6a77f2d53f34f6654abb2b87ca187ae819"
      ],
      "b": [
        [
          "0x24b7d894561776efd697179bacccb3283a8fc17824eae0fcedf290357e802572",
          "0x06ade3553690a716dfe3fea66c0a33b04b0b8f529832e6902c52828cb26e0c5a"
        ],
        [
          "0x0e57ac7541344ff06ba67937bb74d7205a7193f5ab6828a3496aa2459e46d88f",
          "0x2a92e20712cfd116b576df823ec0c88b2efdee69b163ab2727125b25bade0017"
        ]
      ],
      "c": [
        "0x1f11deae71b392a338f3099ba83de267343e6c46f84c99d5dca61474534cbef3",
        "0x0acb9f141c5b7d778db0092218952ebb911c598261e591988e2cd75903d193f4"
      ]
    },
    "inputs": [
      "0x126391ba1fce3db355cf8e759492d32ec35a48787f38d2c1ebd8255e4a84cdf1",
      "0x0000000000000000000000000000000000000000000000000000000000000001",
      "0x0000000000000000000000000000000000000000000000000000000000000005",
      "0x0000000000000000000000000000000000000000000000000000000000000001"
    ]
  };
  let [alice, bob] = accounts;
  let contractInstance;
  let next_gameid = 0;

  beforeEach(async () => {
    contractInstance = await GuessTheNumberGameLayer.deployed();
    console.log(contractInstance.address);
  });

  it("Initiate multiple games", async () => {
    const result = await contractInstance.InitiateGame(proof.proof, proof.inputs, {from: alice});
    assert.equal(result.logs[0].event, "NewGameInitiation");
    assert.equal(result.logs[0].args[0], 0);

    const result2 = await contractInstance.InitiateGame(proof.proof, proof.inputs, {from: alice});
    assert.equal(result.logs[0].event, "NewGameInitiation");
    assert.equal(result2.logs[0].args[0], 1);

    next_gameid = 2;
  });

  it("Initiate and join a single game, make guesses until win", async () => {
    // poll for event? web3 has getPastEvents https://web3js.readthedocs.io/en/v1.2.0/web3-eth-contract.html#getpastevents

    const result = await contractInstance.InitiateGame(proof.proof, proof.inputs, {from: alice});
    assert.equal(result.logs[0].event, "NewGameInitiation");

    let gameid = result.logs[0].args[0];
    assert.equal(gameid, next_gameid);
    next_gameid = next_gameid + 1;

    await contractInstance.JoinGame(gameid, {from: bob});

    let guess = 2;
    const result2 = await contractInstance.MakeGuess(gameid, guess, {from: bob});
    assert.equal(result2.logs[0].event, "GuessMade");
    assert.equal(result2.logs[0].args[0], BigInt(gameid));
    assert.equal(result2.logs[0].args[1], guess);

    // alice reads the event GuessMade emission
    const result3 = await contractInstance.NeedsValidation(gameid, {from: alice});
    assert.equal(result3, true);

    // get guess
    const result5 = await contractInstance.GetGuess(gameid, {from: alice});
    assert.equal(result5, 2);

    // run: 
    // eval_guess.bat eval_guess 3 8317554905031743436470060412079836410388093405773061122028896578523632029169 2
    // and generate the proof.json for another verification
    const proof_secret_more_than = {
      "proof": {
        "a": [
          "0x0753719226eed3ca5fdbe8b6d0a105102d41f6608ec1222fbe72b5306850843b",
          "0x1b3aa2dabdebd0c1bb308bd221c2c35da648747982b9fd730aba3b6cdc39a355"
        ],
        "b": [
          [
            "0x119586b0ee8e3faad8e58ebccedee31ba7ad1d47c91d897d5a04c704d88382a8",
            "0x02c1ed4f3a4321b351cf20a7834287b33fcf14bbbce21d8b8fe2257cbe3cf8c0"
          ],
          [
            "0x17ce458f2d203e3faa4e231a349560d142d639fccfdea144267bca1197609a9f",
            "0x1403b620a15795cd868505cd3588c0f88b282d5f65816aa6360f7d0447bfd776"
          ]
        ],
        "c": [
          "0x192b1b504aa040c3cff6df1b66389ecbcc06e348b49730b939f1d2f9322f7dd3",
          "0x1891833a6c4a77d83370abdfab42ad2ed9deff9b77ee09a93607de4aefff3831"
        ]
      },
      "inputs": [
        "0x126391ba1fce3db355cf8e759492d32ec35a48787f38d2c1ebd8255e4a84cdf1",
        "0x0000000000000000000000000000000000000000000000000000000000000002",
        "0x0000000000000000000000000000000000000000000000000000000000000002"
      ]
    };
    const result6 = await contractInstance.MakeValidation(gameid, proof_secret_more_than.proof, proof_secret_more_than.inputs, {from: alice});
    assert.equal(result6.logs[0].event, "CanGuessAgain");
    assert.equal(result6.logs[0].args[0], BigInt(gameid));
    assert.equal(result6.logs[0].args[1], BigInt(2));

    guess = 4;
    const result7 = await contractInstance.MakeGuess(gameid, guess, {from: bob});
    assert.equal(result7.logs[0].event, "GuessMade");
    assert.equal(result7.logs[0].args[0], BigInt(gameid));
    assert.equal(result7.logs[0].args[1], guess);
    
    // run: 
    // eval_guess.bat eval_guess 3 8317554905031743436470060412079836410388093405773061122028896578523632029169 4
    // and generate the proof.json for another verification
    const proof_secret_less_than = {
      "proof": {
        "a": [
          "0x04b427ee98cc0c41c3635cfed2bda34964be77002df41d4ad84419454dfe4de9",
          "0x17589056d1a5239b956d1ea36eec46a7bc39e12f648caf4c6d41028b6b1af3cf"
        ],
        "b": [
          [
            "0x0d31d5184872bb1046a5ad424c578a75a4dd00a1dca682f4d6dd30b740f25448",
            "0x11d84f80e5630cebd9002bdb7e25dce173a02adbe7d31931896eb9e555cc3e79"
          ],
          [
            "0x20cdae37c2aec820ec6b142b6626713620294ee1e2295a499ea217bebe2b8062",
            "0x06c1b842ed576f466fe71fcc81fdb868797b31fba61c184204ccb81b66b8289d"
          ]
        ],
        "c": [
          "0x2996a97c35794ef520810b4e2ff1ebd3057cba970ce6503b020c5a3f3a560f04",
          "0x23dd7df32caaa7dc6757d48c24854c74de4324bdbccae503dd64d898fc534505"
        ]
      },
      "inputs": [
        "0x126391ba1fce3db355cf8e759492d32ec35a48787f38d2c1ebd8255e4a84cdf1",
        "0x0000000000000000000000000000000000000000000000000000000000000004",
        "0x0000000000000000000000000000000000000000000000000000000000000001"
      ]
    };
    const result8 = await contractInstance.MakeValidation(gameid, proof_secret_less_than.proof, proof_secret_less_than.inputs, {from: alice});
    assert.equal(result8.logs[0].event, "CanGuessAgain");
    assert.equal(result8.logs[0].args[0], BigInt(gameid));
    assert.equal(result8.logs[0].args[1], BigInt(1));

    guess = 3;
    const result9 = await contractInstance.MakeGuess(gameid, guess, {from: bob});
    assert.equal(result9.logs[0].event, "GuessMade");
    assert.equal(result9.logs[0].args[0], BigInt(gameid));
    assert.equal(result9.logs[0].args[1], guess);

    // run: 
    // eval_guess.bat eval_guess 3 8317554905031743436470060412079836410388093405773061122028896578523632029169 3
    // and generate the proof.json for another verification
    const proof_secret_found = {
      "proof": {
        "a": [
          "0x0b9319ac20184e1d1488c9461144c07c1087a0e01efd28a544ae9aa4bcef7b48",
          "0x079d34157741dc95c3b63f2314d43da8b4620d607cf8e3b2daeedb9029e1555e"
        ],
        "b": [
          [
            "0x0eacf0d81f8d9d26c060a1555332a6c736c6fad45a711c2766b1043035f984c4",
            "0x01920b4b28cf966ee9b013e34176ef96a88e15fe8fd285650437f16205249004"
          ],
          [
            "0x129fba36d792608bd2a5f42628af5ef9455dc4e08117a670c235693f161211b4",
            "0x21ca0307f1fb1893c0e9c28f954da55a43d0d0cd9289b9a41fb976273d4d3cf0"
          ]
        ],
        "c": [
          "0x0105651542b766c076768ebdd91e1e3113084c418f1dd9d5a05476c08957b5b4",
          "0x2fb66612b67e8e7c14fa950a50e209ec67b0293d2c74fc593e24780baae35f4a"
        ]
      },
      "inputs": [
        "0x126391ba1fce3db355cf8e759492d32ec35a48787f38d2c1ebd8255e4a84cdf1",
        "0x0000000000000000000000000000000000000000000000000000000000000003",
        "0x0000000000000000000000000000000000000000000000000000000000000000"
      ]
    };
    const result10 = await contractInstance.MakeValidation(gameid, proof_secret_found.proof, proof_secret_found.inputs, {from: alice});
    assert.equal(result10.logs[0].event, "SuccessfulGuess");
    assert.equal(result10.logs[0].args[0], BigInt(gameid));

    const result11 = await contractInstance.GameFinished(gameid);
    assert.equal(result11, true);

    const result12 = await contractInstance.GameGuessCount(gameid);
    assert.equal(result12, 3);
  });

 
  xit("randomfunctions", async () => {
    const result = await contractInstance.PureReturn();
    
    console.log(result); // BigNum type
    let num = result.toString(); // BigNum type
    assert.equal(num, 2);
    assert.equal(num, "2");

    console.log("===");
    const result2 = await contractInstance.CallWithArgs(1, "asr");
    console.log(result2);
    assert.equal(result2, "ret");

    console.log("===");
    const result3 = await contractInstance.CallWithArgsMultipleRet(1, "asr");
    console.log(result3);
    console.log(result3[0]);  //"ret2"
    console.log(result3[1]);  //12

    const {0: strValue, 1: intValue} = result3;
    assert.equal(strValue, "ret2");
    assert.equal(intValue, 12);

    // make and commit a transaction via the CallInteractive function
    // note that you need an event emitted in the solidity code for the logs[] array to populate
    const result4 = await contractInstance.CallInteractive();
    //console.log(result4);
    assert.equal(result4.logs[0].args.val, 3);

    // make a 'call' without actually commiting the transaction
    const result4a = await contractInstance.CallInteractive.call();
    //console.log(result4a);
    assert.equal(result4a, 6);

    const result5 = await contractInstance.CallInteractive();
    assert.equal(result5.logs[0].args.val, 6);

    const result5a = await contractInstance.CallInteractive2.call();
    assert.equal(result5a, 6);
  });
});