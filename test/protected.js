var ProtectedController = artifacts.require("./ProtectedController.sol");

contract("Protected", function(accounts) {
  it("should unlock registerScheme function for key", async function() {
    var protectedController = await ProtectedController.deployed();

    await protectedController.registerScheme();

    assert.isTrue(
      (await protectedController.schemesRegistered.call()).toNumber() == 1
    );
  });

  it("should revert executing locked function without key", async function() {
    var protectedController = await ProtectedController.deployed();
    await assertRevert(protectedController.reset({ from: accounts[1] }));
  });

  it("should unlock reset function for key", async function() {
    var protectedController = await ProtectedController.deployed();

    await protectedController.reset();
    assert.isTrue(
      (await protectedController.schemesRegistered.call()).toNumber() == 0
    );
  });

  it("should revert executing locked function when key already used", async function() {
    var protectedController = await ProtectedController.deployed();

    await protectedController.reset();

    await assertRevert(protectedController.reset({ from: accounts[0] }));
  });

  it("should unlock function when params are correct", async function() {
    var protectedController = await ProtectedController.deployed();

    await protectedController.registerScheme();

    await protectedController.setParam(0, 100);

    assert.isTrue(
      (await protectedController.schemes.call(0)).toNumber() == 100
    );
  });

  it("should revert executing locked function when params are incorrect", async function() {
    var protectedController = await ProtectedController.deployed();

    await protectedController.registerScheme();

    await assertRevert(protectedController.setParam(5, 200));
  });

  it("should transfer key", async function() {
    var protectedController = await ProtectedController.deployed();

    var schemesRegistered = (await protectedController.schemesRegistered.call()).toNumber();

    await protectedController.transferKey(
      "registerScheme",
      accounts[1],
      false,
      web3.eth.getBlock(web3.eth.blockNumber).timestamp + 60 * 60 * 24,
      2
    );

    await protectedController.registerScheme({ from: accounts[1] });

    assert.isTrue(
      (await protectedController.schemesRegistered.call()).toNumber() ==
        schemesRegistered + 1
    );
  });

  it("should revert when transfering non transferable key", async function() {
    var protectedController = await ProtectedController.deployed();

    await assertRevert(
      protectedController.transferKey(
        "registerScheme",
        accounts[2],
        false,
        web3.eth.getBlock(web3.eth.blockNumber).timestamp + 60 * 60 * 12,
        1,
        { from: accounts[1] }
      )
    );
  });

  it("should revert when transfering non existing key", async function() {
    var protectedController = await ProtectedController.deployed();

    await assertRevert(
      protectedController.transferKey(
        "reset",
        accounts[1],
        false,
        web3.eth.getBlock(web3.eth.blockNumber).timestamp + 60 * 60 * 12,
        1
      )
    );
  });

  it("should revoke key", async function() {
    var protectedController = await ProtectedController.deployed();

    await protectedController.uselessFunc();

    await protectedController.revoke("uselessFunc");

    await assertRevert(protectedController.uselessFunc());
  });

  // @notice This test should be last as it change time
  it("should revert executing locked function when date expired", async function() {
    var protectedController = await ProtectedController.deployed();

    await protectedController.registerScheme();

    await timeTravel(60 * 60 * 24 * 5);
    await assertRevert(protectedController.setParam(2, 300));
  });

  it("should revert transfering expired key", async function() {
    var protectedController = await ProtectedController.deployed();

    await assertRevert(
      protectedController.transferKey(
        "reset",
        accounts[1],
        false,
        web3.eth.getBlock(web3.eth.blockNumber).timestamp + 60,
        1
      )
    );
  });
});

async function assertRevert(promise) {
  try {
    await promise;
  } catch (error) {
    const revertFound = error.message.search("revert") >= 0;
    assert(revertFound, `Expected "revert", got ${error} instead`);
    return;
  }
  assert.fail("Expected revert not received");
}

const jsonrpc = "2.0";
const id = 0;
const send = (method, params = []) =>
  web3.currentProvider.send({ id, jsonrpc, method, params });
const timeTravel = async seconds => {
  await send("evm_increaseTime", [seconds]);
  await send("evm_mine");
};
