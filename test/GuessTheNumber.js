
const GuessTheNumberGameLayer = artifacts.require("GuessTheNumberGameLayer");

contract("GuessTheNumberGameLayer", (accounts)=> {

  let [alice, bob] = accounts;
  let contractInstance;
  beforeEach(async () => {
    contractInstance = await GuessTheNumberGameLayer.new();
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
  });
});