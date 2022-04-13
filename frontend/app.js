
const web3 = new Web3("http://127.0.0.1:7545");

const contract_addr = "0xA658C6231baD7adeD3D0bd73658aFEa878eE3b0d";
const player1Addr = "0x37f8D6fFE6c60eA3580A1Ea3fAcbfB3c557a4BbB";
const player2Addr = "0xb80082817e4823F979d0056000bDB451ab192aa7";

var contract_abi;
var contract;

window.addEventListener('load', async function() {
  if (typeof web3 !== 'undefined')
  {
    console.log('web3 detected!' + web3.currentProvider.constructor.name);
    this.window.web3 = new Web3(web3.currentProvider);
  }
  else
  {
    console.log('no web3 detected');
    this.window.web3 = new Web3("http://127.0.0.1:7545")
  }

  // when deployed, you may get contract abi from etherscan via http requests
  contract_abi = await get_contract_abi();
  contract = new web3.eth.Contract(contract_abi["abi"], contract_addr);
})

async function get_contract_abi() {  
  let data = await fetch("http://localhost:3000/game_layer_abi", {
      method: "GET"
    });
  let dat = await data.json();
  return dat;
}

const initiateGameBtn = document.querySelector(".initiate_game_btn");
initiateGameBtn.addEventListener("click", initiateGame);
function initiateGame(event) 
{
  event.preventDefault();

  let lower_range = document.getElementById("lowerrange").value;
  let upper_range = document.getElementById("upperrange").value;
  let secretnum = document.getElementById("secretnum").value;

  // post to localhost:3000/initiate_game

  // then/catch methods, used because browserify can't convert the await keyword
  // fetch("http://localhost:3000/initiate_game",  {
  //     method: "POST",
  //     headers: {'Content-Type': 'application/json' }, 
  //     body: JSON.stringify(['4', '1', '6'])
  // }).then((response) => {
  //   console.log("promise");
  //   console.log(response);
  //   response.json().then(data => { console.log("----"); console.log(data); });
  // }).catch((err) => {
  //   console.log(err);
  // })
  
  async function initiate_game() {  
    let data = await fetch("http://localhost:3000/initiate_game", {
      method: "POST",
      headers: {'Content-Type': 'application/json' }, 
      body: JSON.stringify([secretnum, lower_range, upper_range])
    });
    let initiate_game_json = await data.json();
    
    // // calling pure functions..
    // var val = await contract.methods.PureReturn().call();
    // console.log(val);
    // var val2 = await contract.methods.CallWithArgs(1, "2").call();
    // console.log(val2);
    // var val2a = await contract.methods.CallWithArgs("1", 2).send({from: player1Addr});
    // console.log(val2a);

    //doesnt work, 2nd parameter: number will not implicitly convert to string
    // var val2a = await contract.methods.CallWithArgs("1", 2).send({from: player1Addr}); 

    // // calling a method that introduces a smart contract state change..
    // var val3 = await contract.methods.CallInteractive().send({from: player1Addr});
    // console.log(val3);
    // var val3b = await contract.methods.CallInteractive2().call();
    // console.log(val3b);
    
    var proof = initiate_game_json["proof"];
    var input = initiate_game_json["inputs"]

    var gas = await contract.methods.InitiateGame(proof, input).estimateGas();
    console.log(`InitiateGame gas est: ${gas}`);
    
    try {
      //var ret = await contract.methods.InitiateGame(proof, input).send({ from: player1Addr });
      var ret = await contract.methods.InitiateGame(proof, input).send({ from: player1Addr, gas: 512000 });
      // var ret = await contract.methods.InitiateGame(proof, input).call({ from: player1Addr });
      // console.log(`my game id: ${ret}`);
      console.log(ret);
      document.getElementById("initiate_game_gas").innerHTML = `Gas: ${ret['gasUsed']}`;
      
      var newgameid = ret.events.NewGameInitiation.returnValues['newgameid'];
      document.getElementById("initiate_game_status").innerHTML = `Game id: ${newgameid}`;
      document.getElementById("join_game_input").value = `${newgameid}`;
      document.getElementById("guess_game_id").value = `${newgameid}`;
      document.getElementById("verify_game_id").value = `${newgameid}`;
      document.getElementById("mint_game_id").value = `${newgameid}`;
    } catch (err) {
      console.log("=== err ===");
      console.log(err);
      document.getElementById("initiate_game_status").innerHTML = `Failed to initiate game`;
      return;
    }
  }
  initiate_game();
}

const joinGameBtn = document.querySelector(".join_game_btn");
joinGameBtn.addEventListener("click", joinGame);
function joinGame(event) 
{
  event.preventDefault();

  async function join_game() {
    let game_id = document.getElementById("join_game_input").value;

    try {
      var gas = await contract.methods.JoinGame(game_id).estimateGas({ from: player2Addr, gas: 512000 });
      console.log(`JoinGame gas est: ${gas}`);

      var ret = await contract.methods.JoinGame(game_id).send({ from: player2Addr, gas: 512000 });
      console.log(ret);
      document.getElementById("join_game_status").innerHTML = `Joined game ${game_id}`;
      document.getElementById("join_game_gas").innerHTML = `Gas: ${ret['gasUsed']}`;
    } catch (err) {
      console.log("=== err ===");
      console.log(err);
      document.getElementById("join_game_status").innerHTML = `Failed to join game ${game_id}`;
      return;
    }
  }
  join_game();
}

const guessBtn = document.querySelector(".guess_game_btn");
guessBtn.addEventListener("click", guessGame);
function guessGame(event) 
{
  event.preventDefault();

  async function guess_game() {
    let game_id = document.getElementById("guess_game_id").value;
    let guess = document.getElementById("guess").value;

    try {
      var gas = await contract.methods.MakeGuess(game_id, guess).estimateGas({ from: player2Addr, gas: 512000 });
      console.log(`MakeGuess gas est: ${gas}`);
      
      var ret = await contract.methods.MakeGuess(game_id, guess).send({ from: player2Addr, gas: 512000 });
      console.log(ret);
      document.getElementById("guess_game_status").innerHTML = `Submitted guess for game ${game_id}`;
      document.getElementById("guess_game_gas").innerHTML = `Gas: ${ret['gasUsed']}`;
    } catch (err) {
      console.log("=== err ===");
      console.log(err);
      document.getElementById("guess_game_status").innerHTML = `Failed to submit guess for game ${game_id}`;
      return;
    }

    // var newgameid = ret.events.GuessMade.returnValues['gameid'];
    // var ret_guess = ret.events.GuessMade.returnValues['guess'];
  }
  guess_game();
}

const verifyGameBtn = document.querySelector(".verify_game_btn");
verifyGameBtn.addEventListener("click", verifyGame);
function verifyGame(event) 
{
  event.preventDefault();

  async function verify_guess() {
    let game_id = document.getElementById("verify_game_id").value;
    let secret_number = document.getElementById("secretnum").value;

    if (secret_number == "")
    {
      document.getElementById("verify_game_status").innerHTML = "Enter the secret number(LHS column)!";
      return;
    }

    try {
      console.log("getting guess..")
      var guess = await contract.methods.GetGuess(game_id).call({ from: player1Addr, gas: 512000 });
      console.log(`guess retrieved: ${guess}`);
    } catch(err) {
      console.log("=== err ===");
      console.log(err);
      document.getElementById("verify_game_status").innerHTML = `Failed to verify guess for game ${game_id}`;
      return;
    }
    
    let data = await fetch("http://localhost:3000/eval_guess", {
      method: "POST",
      headers: {'Content-Type': 'application/json' }, 
      body: JSON.stringify([secret_number, guess])
    });
    let eval_guess = await data.json();

    console.log(eval_guess);

    try {
      var gas = await contract.methods.MakeValidation(game_id, eval_guess['proof'], eval_guess['inputs'])
        .estimateGas({ from: player1Addr, gas: 512000 });
      console.log(`MakeValidation gas est: ${gas}`);

      var ret = await contract.methods.MakeValidation(game_id, eval_guess['proof'], eval_guess['inputs'])
        .send({ from: player1Addr, gas: 512000 });
      console.log(ret);

      var guess_text;
      if (ret.events.SuccessfulGuess)
        guess_text = "Guess successful!";
      else if (ret.events.CanGuessAgain)
      {
        var guess_result = ret.events.CanGuessAgain.returnValues['result'];
        if (guess_result == 1)
          guess_text = "Secret number less than guess!";
        else if (guess_result == 2)
          guess_text = "Secret number more than guess!";
      }
      document.getElementById("verify_game_result").innerHTML = guess_text;
      document.getElementById("verify_game_status").innerHTML = `Verified guess for game ${game_id}`;
      document.getElementById("verify_game_gas").innerHTML = `Gas: ${ret['gasUsed']}`;
    } catch (err) {
      console.log("=== err ===");
      console.log(err);
      document.getElementById("verify_game_status").innerHTML = `Failed to verify guess for game ${game_id}`;
      return;
    }

  }
  verify_guess();
}

const mintTokenBtn = document.querySelector(".mint_token_btn");
mintTokenBtn.addEventListener("click", mintToken);
function mintToken(event) 
{
  event.preventDefault();

  async function mint_token() {
    let game_id = document.getElementById("mint_game_id").value;

    try {
      var gas = await contract.methods.MintToken(game_id).estimateGas({ from: player2Addr, gas: 512000 });
      console.log(`MintToken gas est: ${gas}`);

      //weird bug with web3-ganache(?), the solidity code is run correct, but the js doesnt return properly
      var ret = await contract.methods.MintToken(game_id).send({ from: player2Addr, gas: 512000 });
      document.getElementById("mint_token_status").innerHTML = `Minted token ${game_id}`;
      document.getElementById("mint_token_gas").innerHTML = `Gas: ${ret['gasUsed']}`;
    } catch (err) {
      console.log("=== err ===");
      console.log(err);
      document.getElementById("mint_token_status").innerHTML = `Failed to mint token! game_id: ${game_id}`;
      return;
    }
  }
  mint_token();
}


setInterval(function() {

  async function printEvents() {
    var events = await contract.getPastEvents("allEvents", {fromBlock: 0, toBlock: 'latest'});

    var count = 0;
    var reversed_events = events.reverse()
    var console_text = "";
    for (evt of reversed_events)
    {
      console_text += `Event: ${evt['event']}, ReturnValues: {${JSON.stringify(evt['returnValues'])} <br>\n`;
      ++count;
      if (count > 10)
        break;
    }
    document.getElementById("ConsoleLog").innerHTML = console_text;
  }
  printEvents();

}, 3000)