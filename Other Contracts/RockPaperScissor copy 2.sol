// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract RockPaperScissors3 {

  event GameCreated(address creator, uint gameNumber, uint bet);
  event GameStarted(address[2] players, uint gameNumber);
  event GameComplete(address winner, uint gameNumber);
  
  enum GameStates { Created, Started, Completed }
  enum Action {None, Rock, Paper, Scissor}
  
  struct Game {
      address[2] players;
      uint bet;
      uint8[2] moves;
      GameStates gameState;
  }
  
  mapping (uint => Game) GameNumToGame;
  uint gameCount = 0;
  address payable winner;

  uint[4][4] rpsLookup = [  [0,0,0,0],
                            [0,0,2,1], 
                            [0,1,0,2],
                            [0,2,1,0] ];

  function createGame(address payable participant) payable  external{
    require(msg.value > 0);

    GameNumToGame[++gameCount] = Game([msg.sender, participant], msg.value, [0, 0], GameStates.Created);

    emit GameCreated(msg.sender, gameCount, msg.value);
  }
  

  function joinGame(uint gameNumber) payable external{
    Game storage game = GameNumToGame[gameNumber];
    require(game.players[1] == msg.sender);
    require(msg.value >= game.bet);
    require(game.gameState == GameStates.Created);
    
    if(msg.value > game.bet){
        payable(msg.sender).transfer(msg.value - game.bet);
    }

    emit GameStarted(game.players, gameNumber);
    game.gameState = GameStates.Started;
  }
  

  function makeMove(uint gameNumber, uint8 moveNumber) external allowGame(gameNumber, moveNumber){
    
    Game storage game = GameNumToGame[gameNumber];
    if(game.players[0]== msg.sender){
        game.moves[0] = moveNumber;
    } else {
        game.moves[1] = moveNumber;
    }
    if(game.moves[0] > 0 && game.moves[1] > 0){
        uint decision = rpsLookup[game.moves[0]][game.moves[1]]; 
        if(decision == 0){
            payable(game.players[0]).transfer(game.bet);
            payable(game.players[1]).transfer(game.bet);
        
            emit GameComplete(address(0), gameNumber);
        } 
        else {
           winner = payable(game.players[decision - 1]);
           winner.transfer(game.bet*2);
           emit GameComplete(winner, gameNumber);
        }
        game.gameState = GameStates.Completed;
    }        
  }
  
  modifier allowGame(uint gameNumber, uint moveNumber) {
    Game memory game = GameNumToGame[gameNumber];
    require(game.gameState == GameStates.Started);
    require(moveNumber == 1 || moveNumber == 2 || moveNumber == 3);
    require(game.players[0]== msg.sender || game.players[1]== msg.sender);
    _;
  }
  
}