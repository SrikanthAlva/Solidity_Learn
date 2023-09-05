// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract RockPaperScissors2 {

  event GameCreated(address creator, uint gameNumber, uint bet);
  event GameStarted(address[2] players, uint gameNumber);
  event GameComplete(address winner, uint gameNumber);
  
  struct Game {
      address[2] players;
      uint bet;
      uint8 movePlayer1;
      uint8 movePlayer2;
      uint8 playersJoined;
      uint8 gameComplete;
  }
  
  mapping (uint => Game) GameNumToGame;
  uint gameCount = 0;

  uint[3][3] rpsLookup = [  [0,2,1], 
                            [1,0,2],
                            [2,1,0] ];

  function createGame(address payable participant) payable  external{
    require(msg.value > 0);

    GameNumToGame[++gameCount] = Game([msg.sender, participant], msg.value, 0, 0, 0, 0);

    emit GameCreated(msg.sender, gameCount, msg.value);
  }
  

  function joinGame(uint gameNumber) payable external{
    require(GameNumToGame[gameNumber].players[1] == msg.sender);
    require(msg.value >= GameNumToGame[gameNumber].bet);
    require(GameNumToGame[gameNumber].playersJoined == 0);
    
    if(msg.value > GameNumToGame[gameNumber].bet){
        payable(msg.sender).transfer(msg.value - GameNumToGame[gameNumber].bet);
    }

    emit GameStarted(GameNumToGame[gameNumber].players, gameNumber);
    GameNumToGame[gameNumber].playersJoined = 1;
  }
  

  function makeMove(uint gameNumber, uint8 moveNumber) external allowGame(gameNumber, moveNumber){
    if(GameNumToGame[gameNumber].players[0]== msg.sender){
        GameNumToGame[gameNumber].movePlayer1 = moveNumber;
    } else {
        GameNumToGame[gameNumber].movePlayer2 = moveNumber;
    }
    if(GameNumToGame[gameNumber].movePlayer1 > 0 && GameNumToGame[gameNumber].movePlayer2 > 0){
        uint decision = rpsLookup[GameNumToGame[gameNumber].movePlayer1 - 1][GameNumToGame[gameNumber].movePlayer2 - 1];
        if(decision == 0){
            payable(GameNumToGame[gameNumber].players[0]).transfer(GameNumToGame[gameNumber].bet);
            payable(GameNumToGame[gameNumber].players[1]).transfer(GameNumToGame[gameNumber].bet);
        
            emit GameComplete(address(0), gameNumber);
        } else if(decision == 1){
            payable(GameNumToGame[gameNumber].players[0]).transfer(GameNumToGame[gameNumber].bet*2);
            
            emit GameComplete(GameNumToGame[gameNumber].players[0], gameNumber);
        } else {
            payable(GameNumToGame[gameNumber].players[1]).transfer(GameNumToGame[gameNumber].bet*2);
            
            emit GameComplete(GameNumToGame[gameNumber].players[1], gameNumber);
        }
        GameNumToGame[gameNumber].gameComplete = 1;
    }
        
  }

  
  modifier allowGame(uint gameNumber, uint moveNumber) {
    require(GameNumToGame[gameNumber].playersJoined == 1);
    require(GameNumToGame[gameNumber].gameComplete == 0);
    require(moveNumber == 1 || moveNumber == 2 || moveNumber == 3);
    require(GameNumToGame[gameNumber].players[0]== msg.sender || GameNumToGame[gameNumber].players[1]== msg.sender);
    _;
  }
  
}