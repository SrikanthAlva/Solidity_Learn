const RockPaperScissors = artifacts.require("RockPaperScissors4");
const { promisify } = require('util');

function _randomMove() { 
  return Math.ceil(Math.random() * 3);
}

function _compareMoves(move1, move2) {
  if(move1 === move2) return 0;
  if((move1 === 1 && move2 === 3) || (move1 === 2 && move2 === 1) || (move1 === 3 && move2 === 2)) return 1;
  return -1;
}

function findEvent(transaction, evt) {
  let event = transaction.logs.filter(({ event }) => event === evt)[0];
  if(!event) throw `Remember to call ${evt} event!`;
  return event.args;
}

let rps; 
const deploy = async function() {
  if(rps) return rps;
  rps = await RockPaperScissors.new();
  return rps;
}

contract('RockPaperScissors', function(accounts) {
  describe('createGame', function() {
    it("should let us create a game", async function() {
      const contract = await deploy();
      const bet = 1000;
      let transaction = await contract.createGame(accounts[1], { value: bet });
      let gameCreatedEvent = findEvent(transaction, 'GameCreated');
      assert.equal(gameCreatedEvent.creator, accounts[0], `GameCreated Event should include the creators address ${accounts[0]}`);
      assert(gameCreatedEvent.gameNumber, `GameCreated Event should include a game number for us to refer to`);
      assert.equal(gameCreatedEvent.bet, bet, `GameCreated Event should include the bet size`);
    });
    it("should fail to create a game when no bet is placed", async function() {
      const contract = await deploy();
      let exception;
      try { 
        await contract.createGame(accounts[1]);
      }
      catch(ex) {
        exception = ex;
      }
      assert(exception, "An exception should be thrown when no bet is placed");
    });
  });
  describe('joinGame', function() {
    it("should let us join a game for a valid participant", async function() {
      const contract = await deploy();
      const bet = 1000;
      let createGame = await contract.createGame(accounts[1], { value: bet });
      let game = findEvent(createGame, 'GameCreated').gameNumber;
      let joinGame = await contract.joinGame(game, { from: accounts[1], value: bet });
      let players = findEvent(joinGame, 'GameStarted').players;
      assert.isAbove(players.indexOf(accounts[0]), -1, `Could not find ${accounts[0]} in players array on the Game Started Event`);
      assert.isAbove(players.indexOf(accounts[1]), -1, `Could not find ${accounts[1]} in players array on the Game Started Event`);
    });
    it("should let us join a game twice as a valid participant", async function() {
      const contract = await deploy();
      const bet = 1000;
      let createGame = await contract.createGame(accounts[1], { value: bet });
      let game = findEvent(createGame, 'GameCreated').gameNumber;
      await contract.joinGame(game, { from: accounts[1], value: bet });
      let exception;
      try { 
        await contract.joinGame(game, { from: accounts[1], value: bet });
      } 
      catch(ex) {
        exception = ex;
      }
      assert(exception, "An exception should be thrown when a player tries to join a game already started");
    });
    it("should not let us join a game as an invalid participant", async function() {
      const contract = await deploy();
      const bet = 1000;
      let createGame = await contract.createGame(accounts[1], { value: bet });
      let game = findEvent(createGame, 'GameCreated').gameNumber;
      let exception;
      try { 
        await contract.joinGame(game, { from: accounts[2], value: bet });
      } 
      catch(ex) {
        exception = ex;
      }
      assert(exception, "An exception should be thrown when an invalid address joins the game");
    });
    it("should not let us join a game that has not been created", async function() {
      const contract = await deploy();
      let exception;
      try { 
        await contract.joinGame(50, { from: accounts[2], value: 1000 });
      } 
      catch(ex) {
        exception = ex;
      }
      assert(exception, "Should not be able to join a game that has not been created");
    });
    it("should not let us join a game without sending sufficient funds", async function() {
      const contract = await deploy();
      const bet = 1000;
      let createGame = await contract.createGame(accounts[1], { value: bet });
      let game = findEvent(createGame, 'GameCreated').gameNumber;
      let exception;
      try { 
        await contract.joinGame(game, { from: accounts[1], value: 500 });
      } 
      catch(ex) {
        exception = ex;
      }
      assert(exception, "An exception should be thrown when the funds sent are insufficient");
    });
    it("should refund additional funds sent", async function() {
      const contract = await deploy();
      const bet = 1000;
      let createGame = await contract.createGame(accounts[1], { value: bet });
      let game = findEvent(createGame, 'GameCreated').gameNumber;
      let balanceBefore = web3.utils.toBN(await web3.eth.getBalance(accounts[1]));
      let transaction = await contract.joinGame(game, { from: accounts[1], value: 2000 });
      let tx = await web3.eth.getTransaction(transaction.tx);
      let balanceAfter = web3.utils.toBN(await web3.eth.getBalance(accounts[1]));
      const gasUsed = web3.utils.toBN(transaction.receipt.cumulativeGasUsed);
      const gasPrice = web3.utils.toBN(tx.gasPrice);
      let difference = balanceBefore.sub(balanceAfter).sub(gasUsed.mul(gasPrice));
      assert.equal(difference, bet, "The account balance should only subtract the cost of the bet and gas used");
    });
  });
  describe('makeMove', function() {
    it("should not allow invalid moves", async function() {
      const contract = await deploy();
      let createGame = await contract.createGame(accounts[1], { value: 1000 });
      let game = findEvent(createGame, 'GameCreated').gameNumber;
      await contract.joinGame(game, { from: accounts[1], value: 1000 });
      let exception;
      try {
        await contract.makeMove(game, 0, { from: accounts[0] });
      }
      catch(ex) {
        exception = ex;
      }
      assert(exception, "0 should be an invalid move");
    });
    it("should not allow invalid moves - 2", async function() {
      const contract = await deploy();
      let createGame = await contract.createGame(accounts[1], { value: 1000 });
      let game = findEvent(createGame, 'GameCreated').gameNumber;
      await contract.joinGame(game, { from: accounts[1], value: 1000 });
      let exception;
      try {
        await contract.makeMove(game, 4, { from: accounts[0] });
      }
      catch(ex) {
        exception = ex;
      }
      assert(exception, "4 should be an invalid move");
    });
    it("should not allow moves on a non-started game", async function() {
      const contract = await deploy();
      let createGame = await contract.createGame(accounts[1], { value: 1000 });
      let game = findEvent(createGame, 'GameCreated').gameNumber;
      let exception;
      try {
        await contract.makeMove(game, 1, { from: accounts[0] });
      }
      catch(ex) {
        exception = ex;
      }
      assert(exception, "Game should not be started");
    });
    it("should not allow moves on a completed game", async function() {
      const contract = await deploy();
      let createGame = await contract.createGame(accounts[1], { value: 1000 });
      let game = findEvent(createGame, 'GameCreated').gameNumber;
      await contract.joinGame(game, { from: accounts[1], value: 1000 });
      await contract.makeMove(game, 1, { from: accounts[0] });
      await contract.makeMove(game, 2, { from: accounts[1] });
      let exception;
      try {
        await contract.makeMove(game, 1, { from: accounts[0] });
      }
      catch(ex) {
        exception = ex;
      }
      assert(exception, "After both players make moves, the game should be complete. No further moves are allowed.");
    });
//     it("should have correct balances for a winner", async function() {
//       const contract = await deploy();
//       let bet = 1000;
//       let createGame = await contract.createGame(accounts[1], { value: bet });
//       let game = findEvent(createGame, 'GameCreated').gameNumber;
//       await contract.joinGame(game, { from: accounts[1], value: bet });
//       await contract.makeMove(game, 1, { from: accounts[0] });
      
//       let balanceBefore0 = await web3.eth.getBalance(accounts[0]);
//       let balanceBefore1 = await web3.eth.getBalance(accounts[1]);
      
//       let transaction = await contract.makeMove(game, 2, { from: accounts[1] });
//       let winner = findEvent(transaction, 'GameComplete').winner;
      
//       assert.equal(winner, accounts[1], `Expected the winner to be ${accounts[1]}`);
      
//       let tx = web3.eth.getTransaction(transaction.tx);
//       const gasUsed = new web3.toBigNumber(transaction.receipt.cumulativeGasUsed);
      
//       let balanceAfter0 = await web3.eth.getBalance(accounts[0]);
//       let balanceAfter1 = await web3.eth.getBalance(accounts[1]);
      
//       let difference0 = balanceAfter0.minus(balanceBefore0);
//       let difference1 = balanceAfter1.minus(balanceBefore1).plus(gasUsed.times(tx.gasPrice))
      
//       assert.equal(difference0.toString(), "0", "In the event of a winner, the money should be sent to the winning account");
//       assert.equal(difference1.toString(), (bet * 2), "In the event of a winner, the money should be sent to the winning account");
//     });
//     it("should have correct balances for a tie", async function() {
//       const contract = await deploy();
//       let bet = 1000;
//       let createGame = await contract.createGame(accounts[1], { value: bet });
//       let game = findEvent(createGame, 'GameCreated').gameNumber;
//       await contract.joinGame(game, { from: accounts[1], value: bet });
//       await contract.makeMove(game, 1, { from: accounts[0] });
      
//       let balanceBefore0 = await web3.eth.getBalance(accounts[0]);
//       let balanceBefore1 = await web3.eth.getBalance(accounts[1]);
      
//       let transaction = await contract.makeMove(game, 1, { from: accounts[1] });
//       let winner = findEvent(transaction, 'GameComplete').winner;
      
//       assert.equal(winner, 0, `Expected the winner to be the zero address`);
      
//       let tx = web3.eth.getTransaction(transaction.tx);
//       const gasUsed = new web3.toBigNumber(transaction.receipt.cumulativeGasUsed);
      
//       let balanceAfter0 = await web3.eth.getBalance(accounts[0]);
//       let balanceAfter1 = await web3.eth.getBalance(accounts[1]);
      
//       let difference0 = balanceAfter0.minus(balanceBefore0);
//       let difference1 = balanceAfter1.minus(balanceBefore1).plus(gasUsed.times(tx.gasPrice))
      
//       assert.equal(difference0.toString(), bet, "In the event of a tie, both players should receive their money back");
//       assert.equal(difference1.toString(), bet, "In the event of a tie, both players should receive their money back");
//     });
    it("should detect winners at random", async function() {
      const contract = await deploy();
      let bet = 1000;
      for(let i = 0; i < 10; i++) {
        let createGame = await contract.createGame(accounts[1], { value: bet });
        let game = findEvent(createGame, 'GameCreated').gameNumber;
        await contract.joinGame(game, { from: accounts[1], value: bet });
        let move1 = _randomMove();
        let move2 = _randomMove();
        let moveCompare = _compareMoves(move1, move2);
        let expectedWinner = 0;
        if(moveCompare !== 0) {
          expectedWinner = moveCompare === 1 ? accounts[0] : accounts[1];
        }
        await contract.makeMove(game, move1, { from: accounts[0] });
        let transaction = await contract.makeMove(game, move2, { from: accounts[1] });
        let winner = findEvent(transaction, 'GameComplete').winner;
        assert.equal(winner, expectedWinner, `Expected the winner to be ${expectedWinner}`);
      }
    });
  });
});