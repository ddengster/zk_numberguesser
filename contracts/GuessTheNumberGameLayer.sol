
// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.11;

import "@openzeppelin/contracts/utils/Counters.sol";
import "./GuessTheNumber.sol";
import "./initiate_game_verifier.sol";
import "./eval_guess_verifier.sol";

/*****
Manages:
- Signups for games
- Keeps track of player moves
- Keeps track of game results

*****/
contract GuessTheNumberGameLayer is GuessTheNumber {
  using Counters for Counters.Counter;
  
  enum GameStatus  { WAITING, VALIDATION, GUESSING, FINISHED }
  enum GuessResult { EQUAL, LESS_THAN_GUESS, MORE_THAN_GUESS, UNKNOWN }
  struct Game
  {
    GameStatus mStatus;

    address mInitiator;
    address mGuesser;

    uint256 mHashProof;

    uint32 mCurrentGuess;
    GuessResult mGuessResult;
    uint32 mGuessCount;
  }
  mapping (uint256 => Game) mGameIdToGameMapping;
  Counters.Counter private _gameIdCounter;
  event NewGameInitiation(uint256 newgameid);

  // public api
  function InitiateGame(InitiateGameVerifier.Proof memory p, uint[4] memory io) external returns(uint256)
  {
    InitiateGameVerifier i_verifier = new InitiateGameVerifier();
    bool valid = i_verifier.verifyTx(p, io);
    require(valid == true);
    
    uint evaluation = io[3];
    require(evaluation == 1);

    uint lowerrange = io[1];
    uint upperrange = io[2];
    require(lowerrange < upperrange); //an additional check, likely remove for gas savings?

    uint secretnumber_hash = io[0];
    Game memory game = Game(GameStatus.WAITING, msg.sender, address(0),
      secretnumber_hash, 0, GuessResult.UNKNOWN, 0);

    uint256 id = _gameIdCounter.current();
    mGameIdToGameMapping[id] = game;
    _gameIdCounter.increment();

    emit NewGameInitiation(id);
    return id;
  }

  function JoinGame(uint256 gameid) external
  {
    Game storage game = mGameIdToGameMapping[gameid];
    require(game.mStatus == GameStatus.WAITING);
    require(game.mInitiator != address(0));
    require(game.mGuesser == address(0));

    game.mGuesser = msg.sender;
    game.mStatus = GameStatus.GUESSING;
  }

  event GuessMade(uint256 gameid, uint32 guess);
  function MakeGuess(uint256 gameid, uint32 guess) external
  {
    Game storage game = mGameIdToGameMapping[gameid];
    require(game.mStatus == GameStatus.GUESSING);
    require(game.mInitiator != address(0));
    require(game.mGuesser == msg.sender);
    
    game.mCurrentGuess = guess;
    game.mStatus = GameStatus.VALIDATION;
    emit GuessMade(gameid, guess);
  }

  function NeedsValidation(uint256 gameid) external view returns(bool)
  {
    Game storage game = mGameIdToGameMapping[gameid];
    require(game.mInitiator == msg.sender); // only called by initiator, replace with modifier
    return game.mStatus == GameStatus.VALIDATION;
  }

  event SuccessfulGuess(uint256 gameid);
  event CanGuessAgain(uint256 gameid, GuessResult result);
  function MakeValidation(uint256 gameid, EvalGuessVerifier.Proof memory proof, uint[3] memory io) external
  {
    Game storage game = mGameIdToGameMapping[gameid];
    require(game.mStatus == GameStatus.VALIDATION);
    require(game.mInitiator == msg.sender); // only called by initiator

    EvalGuessVerifier verifier = new EvalGuessVerifier();
    bool valid = verifier.verifyTx(proof, io);
    require(valid == true);

    require(game.mHashProof == io[0]);
    
    uint guess = io[1];
    require(game.mCurrentGuess == guess);

    GuessResult result = GuessResult(io[2]);
    require(result <= GuessResult.UNKNOWN);

    game.mGuessCount = game.mGuessCount + 1;
    
    if (result == GuessResult.EQUAL) // correct guess!
    {
      game.mStatus = GameStatus.FINISHED;
      game.mGuessResult = result;
      emit SuccessfulGuess(gameid);
    }
    else
    {
      game.mStatus = GameStatus.GUESSING;
      game.mGuessResult = result;
      emit CanGuessAgain(gameid, result);
    }
  }

  function GameFinished(uint256 gameid) external view returns(bool)
  {
    Game storage game = mGameIdToGameMapping[gameid];
    return (game.mStatus == GameStatus.FINISHED);
  }

  function GameGuessCount(uint256 gameid) external view returns(uint32)
  {
    Game storage game = mGameIdToGameMapping[gameid];
    return game.mGuessCount;
  }

  function GetGuess(uint256 gameid) external view returns(uint32) 
  {
    Game storage game = mGameIdToGameMapping[gameid];
    require(game.mStatus == GameStatus.VALIDATION);
    require(game.mInitiator == msg.sender);
    //0: initial guess, 1: number greater than guess, -1: number less than guess
    return game.mCurrentGuess;
  }


  function PureReturn() external pure returns(int) {
    return 2;
  }

  event ValueSet(int val);
  int interactive = 0;
  function CallInteractive() external returns(int) {
    interactive = interactive + 3;

    // essential for grabbing return values; since instance.CallInteractive() will not return the ret value!
    emit ValueSet(interactive); 
    return interactive;
  }

  function CallInteractive2() external view returns(int) {
    return interactive;
  }

  function CallWithArgs(int num, string memory mystr) external pure returns(string memory) {
    // let newstr = mystr.append(num);
    return "ret";
  }

  function CallWithArgsMultipleRet(int num, string memory mystr) external pure returns(string memory, int) {
    // let newstr = mystr.append(num);
    return ("ret2", 12);
  }
}
