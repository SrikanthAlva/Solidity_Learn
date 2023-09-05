// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract RockPaperScissors4 {

  event GameCreated(address creator, uint gameNumber, uint bet);
  event GameStarted(address[2] players, uint gameNumber);
  event GameComplete(address winner, uint gameNumber);
  
  enum GameStates { Created, Started, Completed }
  enum Action {None, Rock, Paper, Scissor}
  
  struct Game {
      address[2] players;
      uint bet;
      mapping(address => Action) moves;
      GameStates gameState;
  }
  
  mapping (uint => Game) Games;
  uint gameCount = 0;
  address payable winner;

  uint[4][4] rpsLookup = [  [0,0,0,0],
                            [0,0,2,1], 
                            [0,1,0,2],
                            [0,2,1,0] ];

  function createGame(address payable participant) payable  external{
    require(msg.value > 0);
    Game storage game = Games[++gameCount];
    game.players = [msg.sender, participant];
    game.bet = msg.value;
    game.moves[msg.sender] = Action.None;
    game.moves[participant] = Action.None;
    game.gameState = GameStates.Created;

    emit GameCreated(msg.sender, gameCount, msg.value);
  }
  

  function joinGame(uint gameNumber) payable external{
    Game storage game = Games[gameNumber];
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
    
    Game storage game = Games[gameNumber];
    address player1 = game.players[0];
    address player2 = game.players[1];
    if(player1== msg.sender){
        game.moves[player1] = Action(moveNumber);
    } else {
        game.moves[player2] = Action(moveNumber);
    }
    if(game.moves[player1] != Action.None && game.moves[player2] != Action.None){
        uint decision = rpsLookup[uint(game.moves[player1])][uint(game.moves[player2])]; 
        if(decision == 0){
            payable(player1).transfer(game.bet);
            payable(player2).transfer(game.bet);
        
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
    Game storage game = Games[gameNumber];
    require(game.gameState == GameStates.Started);
    require(moveNumber == 1 || moveNumber == 2 || moveNumber == 3);
    require(game.players[0]== msg.sender || game.players[1]== msg.sender);
    _;
  }
  
}