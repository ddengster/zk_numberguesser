
const GuessTheNumberGameLayer = artifacts.require("GuessTheNumberGameLayer");
const BigNumber = require('bignumber.js');

contract("GuessTheNumberGameLayer", (accounts)=> {

  // compute_witness.bat initiate_game 3 8317554905031743436470060412079836410388093405773061122028896578523632029169 1 5
  let proof = {
    "proof": {
      "a": [
        "0x15f3e7abef87d756c0993e279c67774db0f3adf67ef21f480d7c46f4f425f702",
        "0x035792544c8ab7040369eb18d2af11c9a3b825ec694c87891a26e901235b2855"
      ],
      "b": [
        [
          "0x156aaffdb48c0cccb681286ca9b892590da0fe7aebec1c189cdc2a9e4fd85249",
          "0x21d19ebcfac0191a84438015f4151850d49f04e67a20edad3d4278944c616a73"
        ],
        [
          "0x1c3a8294bebeaa063c7ec4d04b73744ce95d39b64ba882c5495318012780a8a7",
          "0x271e49c008a662468eb7ca007de6718921969b8e496139d766ff354a56a2f9ac"
        ]
      ],
      "c": [
        "0x199d4b96088c63d2628d1b2cef90a2545f353dd3c703e84a250d5629ce9ff848",
        "0x180aee602b4b2122070ad26ed27d76fd156abf264f428aee4ca67f263d841fed"
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

  xit("Initiate multiple games", async () => {
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
    // compute_witness.bat eval_guess 3 8317554905031743436470060412079836410388093405773061122028896578523632029169 2
    // and generate the proof.json for another verification
    const proof_secret_more_than = {
      "proof": {
        "a": [
          "0x09e05ee4feb4ccb0a905df68c3697235d2b9da3513aa77c36ffb5409683e93ae",
          "0x2cfc6f92bd28a2125befedf78fea5d288318af2f81f8ed3fb54f8822d21443d1"
        ],
        "b": [
          [
            "0x21fe88187c70f97e508728a41d5013f1978132cb5751ca42d716976953881046",
            "0x0922657657d7d3c3f38e702c31bda48ea8e2b1122b41e94d15b76f99ff44d4fc"
          ],
          [
            "0x0c9a459e36acecb9afd47e7872b4837fd8eed75a5840e4d3a70a58617085aa23",
            "0x052d6c274f7fcf3aca67275c5679aaf7d8659bf8e99d48c4b896edcc69b2f20e"
          ]
        ],
        "c": [
          "0x15981fcdc80924e93f972032b9ca84a40114b41d19e5e5df8d9bbc1b1f6f251a",
          "0x16e937b7d8deba86d9b308938bdea9700d8345a20cebcf35d75c75efe7aca2d6"
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
    // compute_witness.bat eval_guess 3 8317554905031743436470060412079836410388093405773061122028896578523632029169 4
    // and generate the proof.json for another verification
    const proof_secret_less_than = {
      "proof": {
        "a": [
          "0x0078165ebefa9dd145ce08f62d089d5e474816132171ed7ec4630e83a3bd8744",
          "0x28256228b7b586cc1826d34386e92aaafe28a087df3f5e0e421d2661958eb9c7"
        ],
        "b": [
          [
            "0x2e9f02d49a63da0b42f4ee0675e99d956cd6494e736882f17e577f7ba42ada35",
            "0x19950ebabae7f20e974b50f5dfcb29de17f00b45563c0a7002c0c11d3a503141"
          ],
          [
            "0x223b845e9b269913b276c51aec3117ba8fa8d7ddd4adfc935078511a9f6d0296",
            "0x08226aac7ee559fe6aa1ed5194b364cfb5b220fc56a9f7410f07d60d2d72261c"
          ]
        ],
        "c": [
          "0x1a9b48d15b7757c6e12918baf371e9be5a5e3c7433ff85c38e72f636f806747f",
          "0x26dbef7c71231e7f6dcc50322a4ab39b0a4ad441364af6e8ce0c4a1b9542d722"
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
    // compute_witness.bat eval_guess 3 8317554905031743436470060412079836410388093405773061122028896578523632029169 4
    // and generate the proof.json for another verification
    const proof_secret_found = {
      "proof": {
        "a": [
          "0x01d020b7be5cf356a3b2428d72243ffc3ce65efbb64cf2d7939a95d7ab7616fc",
          "0x300d4526a2d956e182fbcde3a14d2b00f8a8a0da73945125179df91512b34ba0"
        ],
        "b": [
          [
            "0x0c5b2f2ebf8dba0258920366069b99a11a7641b6469d109939cfa49015fc39e4",
            "0x2eb44d5282a3a12cb6b83383e5689eba2e33608e724ca8adf9bdaf13658b3bd7"
          ],
          [
            "0x017018e6f1ade5cf16b1e95260bde4e593f32af392f2c5d29faaeabc56ba81e4",
            "0x1f5e21abf66e5c47d6fdb333d857618b68da4899b647c70e16caf7c6826ebc0b"
          ]
        ],
        "c": [
          "0x165999b536169a136637da9a4fd0c326e8b3c03c5f966968bc5a6d722434337a",
          "0x08864673de687c97c249ca57af550b743665bb133fb052e13703bdaa82faafe2"
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