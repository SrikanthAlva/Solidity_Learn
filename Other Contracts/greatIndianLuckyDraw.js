const GreatIndianLuckyDraw = artifacts.require('GreatIndianLuckyDraw');
contract('GreatIndianLuckyDraw', () => {
  let greatIndianLuckyDraw = null;
  let accounts = null;
  before(async () => {
    greatIndianLuckyDraw = await GreatIndianLuckyDraw.deployed();
    //accounts = web3.eth.getAccounts();
  })

  it('should be deployed', async() => {
    const manager = await greatIndianLuckyDraw.manager();
    assert(manager == 0x39551231933087cbbc76b26b069794d270733af0 );
    assert(greatIndianLuckyDraw != '');    
  })


  it('should accept 0.1 ether', async() => {
    // await greatIndianLuckyDraw.enter.call({value: web3.utils.toWei('0.1', 'ether')});
    await greatIndianLuckyDraw.enter(null, {value: 100000000000000000});
    console.log("Next Level");
    const players = await greatIndianLuckyDraw.players(); 
    console.log("Players", players);
    // const ids = players.map(pyr => pyr.toNumber());
    // assert.deepEqual(ids, [123,1223,12323]);
    assert(greatIndianLuckyDraw != '');    
  })



//   it('should add an element to ids array', async() => {    
//     await advancedStorage.add(123);
//     const result = await advancedStorage.get(0);
//     assert(result.toNumber() === 123);
//   })
//   it('should get an element from ids array', async() => {    
//     await advancedStorage.add(1223);
//     await advancedStorage.add(12323);
//     const result1 = await advancedStorage.get(1);
//     const result2 = await advancedStorage.get(2);
//     assert(result1.toNumber() === 1223);    
//     assert(result2.toNumber() === 12323);
//   })

//   it('should get all ids in the array', async() => {    
//     const allIds = await advancedStorage.getAll(); 
//     const ids = allIds.map(id => id.toNumber());
//     assert.deepEqual(ids, [123,1223,12323]); 
//   })

//   it('should get length of ids array', async() => {    
//     const length = await advancedStorage.length();     
//     assert(length.toNumber() === 3); 
//   })




})