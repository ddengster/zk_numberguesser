
// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.11;

import "@openzeppelin/contracts/utils/Counters.sol";
import "./GuessTheNumber.sol";
import "./initiate_game_verifier.sol";

/*****
Manages:
- Signups for games
- Keeps track of player moves
- Keeps track of game results

*****/
contract GuessTheNumberGameLayer is GuessTheNumber, Verifier2 {
  using Counters for Counters.Counter;
  
  // game ownership states
  enum GameStatus { WAITING, VALIDATION, GUESSING, FINISHED }
  struct Game
  {
    GameStatus mStatus;

    address mInitiator;
    address mGuesser;

    uint256 mHashProof;

    uint32 mCurrentGuess;
    uint32 mGuessValidationResult;
  }
  mapping (uint256 => Game) mGameIdToGameMapping;
  Counters.Counter private _gameIdCounter;

  // public api
  function InitiateGame(Verifier2.Proof memory p, uint[2] memory input, uint256 myhash) external returns(uint256)
  {

    bool result = verifyTx(p, input);
    require(result == true);
    //bool result = verifyProof();
    //require(result == true);

    Game memory game = Game(GameStatus.WAITING, msg.sender, address(0),
      0, 0, 0);

    uint256 id = _gameIdCounter.current();
    mGameIdToGameMapping[id] = game;
    _gameIdCounter.increment();
    return id;
  }

  function JoinGame(uint256 gameid) external
  {
    Game memory game = mGameIdToGameMapping[gameid];
    require(game.mStatus == GameStatus.WAITING);
    require(game.mInitiator != address(0));
    require(game.mGuesser == address(0));

    game.mGuesser = msg.sender;
    game.mStatus = GameStatus.GUESSING;
  }

  function MakeGuess(uint256 gameid, uint32 guess) external
  {
    Game memory game = mGameIdToGameMapping[gameid];
    require(game.mStatus == GameStatus.GUESSING);
    require(game.mInitiator != address(0));
    require(game.mGuesser == msg.sender);
    
    game.mCurrentGuess = guess;
    game.mStatus = GameStatus.VALIDATION;
  }

  function NeedsValidation(uint256 gameid) external returns(uint32)
  {
    Game memory game = mGameIdToGameMapping[gameid];
    require(game.mStatus == GameStatus.VALIDATION);
    require(game.mInitiator == msg.sender); // only called by initiator
    return game.mCurrentGuess;
  }

  function MakeValidation(uint256 gameid, uint32 hashproof, uint32 result) external
  {
    Game memory game = mGameIdToGameMapping[gameid];
    require(game.mStatus == GameStatus.VALIDATION);
    require(game.mInitiator == msg.sender); // only called by initiator

    //bool verified = verifyProof(hashproof);
    // if (verified)
    if (result == 0) // correct guess!
    {
      game.mStatus = GameStatus.FINISHED;
    }
    else
    {
      game.mStatus = GameStatus.GUESSING;
      game.mGuessValidationResult = result;
    }
  }

  function CanGuessAgain(uint256 gameid) external returns(uint32)
  {
    Game memory game = mGameIdToGameMapping[gameid];
    require(game.mStatus == GameStatus.GUESSING);
    require(game.mGuesser  == msg.sender);
    //0: initial guess, 1: number greater than guess, -1: number less than guess
    return game.mGuessValidationResult;
  }

  function GameFinished(uint256 gameid) external returns(bool)
  {
    Game memory game = mGameIdToGameMapping[gameid];
    return (game.mStatus == GameStatus.FINISHED);
  }

  function PureReturn() external pure returns(int) {
    return 2;
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
