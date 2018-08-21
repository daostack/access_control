const { key, empty, event, forward, now, hour } = require("./utils");
const ProtectedMock = artifacts.require("./test/PermissionedMock.sol");

const BigNumber = web3.BigNumber;
require("chai")
  .use(require("chai-bignumber")(BigNumber))
  .use(require("chai-as-promised"))
  .use(require("chai-almost")(7)) // 7 seconds tolerance
  .should();

contract("Protected", accounts => {
  const _id =
    "0x1000000000000000000000000000000000000000000000000000000000000000";
  web3.eth.defaultAccount = accounts[0];
  const _owner = web3.eth.defaultAccount;

  let instance;
  let time;
  beforeEach(async () => {
    time = now();
    instance = await ProtectedMock.new();
  });

  it("revokeOwnerKey deletes key and emits event", async () => {
    await instance.grantFullKey_(_id, _owner);
    const tx = await instance.revokeOwnerKey_(_id, _owner);

    // deletes key
    const k = key(await instance.keys(_id, _owner));
    assert.isTrue(empty(k), "key should now be deleted");

    // emits event
    const RevokeKey = event(tx, "RevokeKey").args;
    RevokeKey._id.should.be.bignumber.equal(_id);
    RevokeKey._owner.should.be.bignumber.equal(_owner);
  });

  it("grantKey reverts when _expiration is in the past", async () => {
    const [_assignable, _expiration, _uses] = [true, time - 1 * hour, 6];
    instance
      .grantKey_(_id, _owner, _assignable, _expiration, _uses)
      .should.be.rejectedWith("revert");
  });

  it("grantKey updates keys and emits an event", async () => {
    const [_assignable, _expiration, _uses] = [true, time + 1 * hour, 6];
    const tx = await instance.grantKey_(
      _id,
      _owner,
      _assignable,
      _expiration,
      _uses
    );
    const k = key(await instance.keys(_id, _owner));

    // updates key
    expect(k.exists).to.equal(true);
    expect(k.assignable).to.equal(_assignable);
    k.expiration.should.to.be.bignumber.equal(_expiration);
    k.uses.should.to.be.bignumber.equal(_uses);

    // emits event
    const AssignKey = event(tx, "AssignKey").args;
    AssignKey._id.should.be.bignumber.equal(_id);
    AssignKey._from.should.be.bignumber.equal(0);
    AssignKey._to.should.be.bignumber.equal(_owner);
    AssignKey._assignable.should.be.equal(_assignable);
    AssignKey._expiration.should.be.bignumber.equal(_expiration);
    AssignKey._uses.should.be.bignumber.equal(_uses);
  });

  it("grantFullKey reverts when _expiration is in the past", async () => {
    const [_assignable, _expiration, _uses] = [true, time - 1 * hour, 6];
    instance
      .grantKey_(_id, _owner, _assignable, _expiration, _uses)
      .should.be.rejectedWith("revert");
  });

  it("grantFullKey updates keys and emits an event", async () => {
    const [_assignable, _expiration, _uses] = [true, 0, 0];
    const tx = await instance.grantFullKey_(_id, _owner);
    const k = key(await instance.keys(_id, _owner));

    // updates key
    expect(k.exists).to.equal(true);
    expect(k.assignable).to.equal(_assignable);
    k.expiration.should.to.be.bignumber.equal(_expiration);
    k.uses.should.to.be.bignumber.equal(_uses);

    // emits event
    const AssignKey = event(tx, "AssignKey").args;
    AssignKey._id.should.be.bignumber.equal(_id);
    AssignKey._from.should.be.bignumber.equal(0);
    AssignKey._to.should.be.bignumber.equal(_owner);
    AssignKey._assignable.should.be.equal(_assignable);
    AssignKey._expiration.should.be.bignumber.equal(_expiration);
    AssignKey._uses.should.be.bignumber.equal(_uses);
  });

  it("unlock decrements _uses if greater than 1 and returns true", async () => {
    const [_assignable, _expiration, _uses] = [false, 0, 5];
    await instance.grantKey_(_id, _owner, _assignable, _expiration, _uses);
    await instance.unlock_(_id);
    const result = await instance.unlock_.call(_id);
    expect(result).to.equal(true);
    const k = key(await instance.keys(_id, _owner));

    // updates key
    expect(k.exists).to.equal(true, "key should still exist");
    expect(k.assignable).to.equal(
      _assignable,
      "key should be still _assignable"
    );
    k.expiration.should.to.be.bignumber.equal(
      _expiration,
      "key should have the same _expiration"
    );
    k.uses.should.to.be.bignumber.equal(
      _uses - 1,
      "key should have 1 less _uses"
    );
  });

  it.skip("unlock deletes key if _uses equal _to 1 and returns true", async () => {
    const [_assignable, _expiration, _uses] = [false, 0, 1];
    await instance.grantKey_(_id, _owner, _assignable, _expiration, _uses);
    await instance.unlock_(_id);
    const result = await instance.unlock_.call(_id);
    expect(result).to.equal(true, "result should be true");
    const k = key(await instance.keys(_id, _owner));

    // updates key
    assert.isTrue(empty(k), "key should now be deleted");
  });

  it("unlock returns false for non-existent key", async () => {
    const result = await instance.unlock_.call(_id);
    expect(result).to.equal(false, "result should be false");
  });

  it("unlock returns false for expired key", async () => {
    const [_assignable, _expiration, _uses] = [false, time + 5 * hour, 5];
    await instance.grantKey_(_id, _owner, _assignable, _expiration, _uses);
    await forward(5 * hour);
    now().should.almost.equal(time + 5 * hour);
    const result = await instance.unlock_.call(_id);
    expect(result).to.equal(false, "result should be false");
  });

  it("isValidExpiration should return true for infinite _expiration", async () => {
    let result = await instance.isValidExpiration(0);
    expect(result).to.equal(true);
    await forward(10 * hour);
    now().should.almost.equal(time + 10 * hour);
    result = await instance.isValidExpiration(0);
    expect(result).to.equal(true);
  });

  it.skip("isValidExpiration should work for finite _expiration", async () => {
    let result = await instance.isValidExpiration(time + 5 * hour);
    expect(result).to.equal(true, "should return true for current time");
    await forward(4 * hour);
    now().should.almost.equal(time + 4 * hour);
    result = await instance.isValidExpiration(time + 5 * hour);
    expect(result).to.equal(
      true,
      "should return true for 1 time before _expiration"
    );
    await forward(1 * hour);
    now().should.almost.equal(time + 5 * hour);
    result = await instance.isValidExpiration(time + 5 * hour);
    expect(result).to.equal(
      true,
      "should return true for the _expiration time"
    );
    await forward(1 * hour);
    now().should.almost.equal(time + 6 * hour);
    result = await instance.isValidExpiration(time + 5 * hour);
    expect(result).to.equal(
      false,
      "should return false for 1 time after _expiration"
    );
  });

  it("unlockable returns false for non-existent key", async () => {
    const result = await instance.unlockable(_id, _owner);
    expect(result).to.equal(false);
  });

  it("unlockable returns false for expired key", async () => {
    const [_assignable, _expiration, _uses] = [false, time + 5 * hour, 5];
    await instance.grantKey_(_id, _owner, _assignable, _expiration, _uses);
    let result = await instance.unlockable(_id, _owner);
    expect(result).to.equal(true);
    await forward(5 * hour);
    now().should.almost.equal(time + 5 * hour);
    result = await instance.unlockable(_id, _owner);
    expect(result).to.equal(false);
  });

  it("unlockable returns true for key with no _expiration", async () => {
    const [_assignable, _expiration, _uses] = [false, 0, 5];
    await instance.grantKey_(_id, _owner, _assignable, _expiration, _uses);
    let result = await instance.unlockable(_id, _owner);
    expect(result).to.equal(true);
    await forward(5 * hour);
    now().should.almost.equal(time + 5 * hour);
    result = await instance.unlockable(_id, _owner);
    expect(result).to.equal(true);
  });

  it("assignKey updates both keys for correct params (no merge) and emits event", async () => {
    const [_assignable, _expiration, _uses] = [true, time + 5 * hour, 5];
    await instance.grantKey_(_id, _owner, _assignable, _expiration, _uses);

    // recipient key
    let recipientKey = key(await instance.keys(_id, accounts[1]));
    assert.isTrue(
      empty(recipientKey),
      "recipient should not have a key before assignKey"
    );

    const tx = await instance.assignKey(
      _id,
      accounts[1],
      false,
      time + 4 * hour,
      3
    );

    // _owner key
    const ownerKey = key(await instance.keys(_id, _owner));
    expect(ownerKey.exists).to.equal(true, "_owner key should still exist");
    expect(ownerKey.assignable).to.equal(
      true,
      "_owner key should still be _assignable"
    );
    ownerKey.expiration.should.be.bignumber.equal(
      _expiration,
      "_owner key should still have the same _expiration"
    );
    ownerKey.uses.should.be.bignumber.equal(
      _uses - 3,
      "_owner key should have 3 _uses less than before"
    );

    // recipient key
    recipientKey = key(await instance.keys(_id, accounts[1]));
    expect(recipientKey.exists).to.equal(
      true,
      "recipient key should now exist"
    );
    expect(recipientKey.assignable).to.equal(
      false,
      "recipient should not be _assignable"
    );
    recipientKey.expiration.should.be.bignumber.equal(
      time + 4 * hour,
      "recipient key should have correct _expiration"
    );
    recipientKey.uses.should.be.bignumber.equal(
      3,
      "recipient key should have correct _uses"
    );

    // emits event
    const AssignKey = event(tx, "AssignKey").args;
    AssignKey._id.should.be.bignumber.equal(_id);
    AssignKey._from.should.be.bignumber.equal(_owner);
    AssignKey._to.should.be.bignumber.equal(accounts[1]);
    AssignKey._assignable.should.be.equal(false);
    AssignKey._expiration.should.be.bignumber.equal(time + 4 * hour);
    AssignKey._uses.should.be.bignumber.equal(3);
  });

  it("assignKey updates both keys for correct params (no merge, recipeint key is expired) and emits event", async () => {
    const [_assignable, _expiration, _uses] = [true, time + 10 * hour, 5];
    await instance.grantKey_(_id, _owner, _assignable, _expiration, _uses);
    await instance.grantKey_(_id, accounts[1], false, time + 5 * hour, 7);
    await forward(5 * hour);
    now().should.almost.equal(time + 5 * hour);

    // recipient key
    let recipientKey = key(await instance.keys(_id, accounts[1]));
    expect(recipientKey.exists).to.equal(
      true,
      "recipient key should exist at the begining"
    );
    expect(recipientKey.assignable).to.equal(
      false,
      "recipient should be not _assignable at the begining"
    );
    recipientKey.expiration.should.be.bignumber.equal(
      time + 5 * hour,
      "recipient key should have correct _expiration at the begining"
    );
    recipientKey.uses.should.be.bignumber.equal(
      7,
      "recipient key should have correct _uses at the begining"
    );

    const tx = await instance.assignKey(
      _id,
      accounts[1],
      false,
      time + 10 * hour,
      3
    );

    // _owner key
    const ownerKey = key(await instance.keys(_id, _owner));
    expect(ownerKey.exists).to.equal(true, "_owner key should still exist");
    expect(ownerKey.assignable).to.equal(
      true,
      "_owner key should still be _assignable"
    );
    ownerKey.expiration.should.be.bignumber.equal(
      _expiration,
      "_owner key should still have the same _expiration"
    );
    ownerKey.uses.should.be.bignumber.equal(
      _uses - 3,
      "_owner key should have 3 _uses less than before"
    );

    // recipient key
    recipientKey = key(await instance.keys(_id, accounts[1]));
    expect(recipientKey.exists).to.equal(
      true,
      "recipient key should still exist"
    );
    expect(recipientKey.assignable).to.equal(
      false,
      "recipient should still not be _assignable"
    );
    recipientKey.expiration.should.be.bignumber.equal(
      time + 10 * hour,
      "recipient key should have correct _expiration"
    );
    recipientKey.uses.should.be.bignumber.equal(
      3,
      "recipient key should have correct _uses"
    );

    // emits event
    const AssignKey = event(tx, "AssignKey").args;
    AssignKey._id.should.be.bignumber.equal(_id);
    AssignKey._from.should.be.bignumber.equal(_owner);
    AssignKey._to.should.be.bignumber.equal(accounts[1]);
    AssignKey._assignable.should.be.equal(false);
    AssignKey._expiration.should.be.bignumber.equal(time + 10 * hour);
    AssignKey._uses.should.be.bignumber.equal(3);
  });

  it("assignKey updates both keys for correct params (merge) and emits event", async () => {
    const [_assignable, _expiration, _uses] = [true, time + 5 * hour, 5];
    await instance.grantKey_(_id, _owner, _assignable, _expiration, _uses);
    await instance.grantKey_(_id, accounts[1], false, time + 4 * hour, 7);

    // recipient key
    let recipientKey = key(await instance.keys(_id, accounts[1]));
    expect(recipientKey.exists).to.equal(
      true,
      "recipient key should exist at the begining"
    );
    expect(recipientKey.assignable).to.equal(
      false,
      "recipient should be not _assignable at the begining"
    );
    recipientKey.expiration.should.be.bignumber.equal(
      time + 4 * hour,
      "recipient key should have correct _expiration at the begining"
    );
    recipientKey.uses.should.be.bignumber.equal(
      7,
      "recipient key should have correct _uses at the begining"
    );

    const tx = await instance.assignKey(
      _id,
      accounts[1],
      false,
      time + 4 * hour,
      3
    );

    // _owner key
    const ownerKey = key(await instance.keys(_id, _owner));
    expect(ownerKey.exists).to.equal(true, "_owner key should still exist");
    expect(ownerKey.assignable).to.equal(
      true,
      "_owner key should still be _assignable"
    );
    ownerKey.expiration.should.be.bignumber.equal(
      _expiration,
      "_owner key should still have the same _expiration"
    );
    ownerKey.uses.should.be.bignumber.equal(
      _uses - 3,
      "_owner key should have 3 _uses less than before"
    );

    // recipient key
    recipientKey = key(await instance.keys(_id, accounts[1]));
    expect(recipientKey.exists).to.equal(
      true,
      "recipient key should still exist"
    );
    expect(recipientKey.assignable).to.equal(
      false,
      "recipient should still not be _assignable"
    );
    recipientKey.expiration.should.be.bignumber.equal(
      time + 4 * hour,
      "recipient key should have correct _expiration"
    );
    recipientKey.uses.should.be.bignumber.equal(
      10,
      "recipient key should have correct _uses"
    );

    // emits event
    const AssignKey = event(tx, "AssignKey").args;
    AssignKey._id.should.be.bignumber.equal(_id);
    AssignKey._from.should.be.bignumber.equal(_owner);
    AssignKey._to.should.be.bignumber.equal(accounts[1]);
    AssignKey._assignable.should.be.equal(false);
    AssignKey._expiration.should.be.bignumber.equal(time + 4 * hour);
    AssignKey._uses.should.be.bignumber.equal(3);
  });

  it("assignKey updates both keys for correct params (merge, infinite _owner _uses, passing infnite _uses) and emits event", async () => {
    const [_assignable, _expiration, _uses] = [true, time + 5 * hour, 0];
    await instance.grantKey_(_id, _owner, _assignable, _expiration, _uses);
    await instance.grantKey_(_id, accounts[1], false, time + 4 * hour, 7);

    // recipient key
    let recipientKey = key(await instance.keys(_id, accounts[1]));
    expect(recipientKey.exists).to.equal(
      true,
      "recipient key should exist at the begining"
    );
    expect(recipientKey.assignable).to.equal(
      false,
      "recipient should be not _assignable at the begining"
    );
    recipientKey.expiration.should.be.bignumber.equal(
      time + 4 * hour,
      "recipient key should have correct _expiration at the begining"
    );
    recipientKey.uses.should.be.bignumber.equal(
      7,
      "recipient key should have correct _uses at the begining"
    );

    const tx = await instance.assignKey(
      _id,
      accounts[1],
      false,
      time + 4 * hour,
      0
    );

    // _owner key
    const ownerKey = key(await instance.keys(_id, _owner));
    expect(ownerKey.exists).to.equal(true, "_owner key should still exist");
    expect(ownerKey.assignable).to.equal(
      true,
      "_owner key should still be _assignable"
    );
    ownerKey.expiration.should.be.bignumber.equal(
      _expiration,
      "_owner key should still have the same _expiration"
    );
    ownerKey.uses.should.be.bignumber.equal(
      0,
      "_owner key should still have infinite _uses"
    );

    // recipient key
    recipientKey = key(await instance.keys(_id, accounts[1]));
    expect(recipientKey.exists).to.equal(
      true,
      "recipient key should still exist"
    );
    expect(recipientKey.assignable).to.equal(
      false,
      "recipient should still not be _assignable"
    );
    recipientKey.expiration.should.be.bignumber.equal(
      time + 4 * hour,
      "recipient key should have correct _expiration"
    );
    recipientKey.uses.should.be.bignumber.equal(
      0,
      "recipient key should have correct _uses"
    );

    // emits event
    const AssignKey = event(tx, "AssignKey").args;
    AssignKey._id.should.be.bignumber.equal(_id);
    AssignKey._from.should.be.bignumber.equal(_owner);
    AssignKey._to.should.be.bignumber.equal(accounts[1]);
    AssignKey._assignable.should.be.equal(false);
    AssignKey._expiration.should.be.bignumber.equal(time + 4 * hour);
    AssignKey._uses.should.be.bignumber.equal(0);
  });

  it("assignKey updates both keys for correct params (merge, infinite _owner _uses, passing finite _uses) and emits event", async () => {
    const [_assignable, _expiration, _uses] = [true, time + 5 * hour, 0];
    await instance.grantKey_(_id, _owner, _assignable, _expiration, _uses);
    await instance.grantKey_(_id, accounts[1], false, time + 4 * hour, 7);

    // recipient key
    let recipientKey = key(await instance.keys(_id, accounts[1]));
    expect(recipientKey.exists).to.equal(
      true,
      "recipient key should exist at the begining"
    );
    expect(recipientKey.assignable).to.equal(
      false,
      "recipient should be not _assignable at the begining"
    );
    recipientKey.expiration.should.be.bignumber.equal(
      time + 4 * hour,
      "recipient key should have correct _expiration at the begining"
    );
    recipientKey.uses.should.be.bignumber.equal(
      7,
      "recipient key should have correct _uses at the begining"
    );

    const tx = await instance.assignKey(
      _id,
      accounts[1],
      false,
      time + 4 * hour,
      3
    );

    // _owner key
    const ownerKey = key(await instance.keys(_id, _owner));
    expect(ownerKey.exists).to.equal(true, "_owner key should still exist");
    expect(ownerKey.assignable).to.equal(
      true,
      "_owner key should still be _assignable"
    );
    ownerKey.expiration.should.be.bignumber.equal(
      _expiration,
      "_owner key should still have the same _expiration"
    );
    ownerKey.uses.should.be.bignumber.equal(
      0,
      "_owner key should still have infinite _uses"
    );

    // recipient key
    recipientKey = key(await instance.keys(_id, accounts[1]));
    expect(recipientKey.exists).to.equal(
      true,
      "recipient key should still exist"
    );
    expect(recipientKey.assignable).to.equal(
      false,
      "recipient should still not be _assignable"
    );
    recipientKey.expiration.should.be.bignumber.equal(
      time + 4 * hour,
      "recipient key should have correct _expiration"
    );
    recipientKey.uses.should.be.bignumber.equal(
      10,
      "recipient key should have correct _uses"
    );

    // emits event
    const AssignKey = event(tx, "AssignKey").args;
    AssignKey._id.should.be.bignumber.equal(_id);
    AssignKey._from.should.be.bignumber.equal(_owner);
    AssignKey._to.should.be.bignumber.equal(accounts[1]);
    AssignKey._assignable.should.be.equal(false);
    AssignKey._expiration.should.be.bignumber.equal(time + 4 * hour);
    AssignKey._uses.should.be.bignumber.equal(3);
  });

  it("assignKey updates both keys for correct params (merge, infinite recipient _uses) and emits event", async () => {
    const [_assignable, _expiration, _uses] = [true, time + 5 * hour, 5];
    await instance.grantKey_(_id, _owner, _assignable, _expiration, _uses);
    await instance.grantKey_(_id, accounts[1], false, time + 4 * hour, 0);

    // recipient key
    let recipientKey = key(await instance.keys(_id, accounts[1]));
    expect(recipientKey.exists).to.equal(
      true,
      "recipient key should exist at the begining"
    );
    expect(recipientKey.assignable).to.equal(
      false,
      "recipient should be not _assignable at the begining"
    );
    recipientKey.expiration.should.be.bignumber.equal(
      time + 4 * hour,
      "recipient key should have correct _expiration at the begining"
    );
    recipientKey.uses.should.be.bignumber.equal(
      0,
      "recipient key should have correct _uses at the begining"
    );

    const tx = await instance.assignKey(
      _id,
      accounts[1],
      false,
      time + 4 * hour,
      3
    );

    // _owner key
    const ownerKey = key(await instance.keys(_id, _owner));
    expect(ownerKey.exists).to.equal(true, "_owner key should still exist");
    expect(ownerKey.assignable).to.equal(
      true,
      "_owner key should still be _assignable"
    );
    ownerKey.expiration.should.be.bignumber.equal(
      _expiration,
      "_owner key should still have the same _expiration"
    );
    ownerKey.uses.should.be.bignumber.equal(
      _uses - 3,
      "_owner key should have 3 _uses less than before"
    );

    // recipient key
    recipientKey = key(await instance.keys(_id, accounts[1]));
    expect(recipientKey.exists).to.equal(
      true,
      "recipient key should still exist"
    );
    expect(recipientKey.assignable).to.equal(
      false,
      "recipient should still not be _assignable"
    );
    recipientKey.expiration.should.be.bignumber.equal(
      time + 4 * hour,
      "recipient key should have correct _expiration"
    );
    recipientKey.uses.should.be.bignumber.equal(
      0,
      "recipient key should have correct _uses"
    );

    // emits event
    const AssignKey = event(tx, "AssignKey").args;
    AssignKey._id.should.be.bignumber.equal(_id);
    AssignKey._from.should.be.bignumber.equal(_owner);
    AssignKey._to.should.be.bignumber.equal(accounts[1]);
    AssignKey._assignable.should.be.equal(false);
    AssignKey._expiration.should.be.bignumber.equal(time + 4 * hour);
    AssignKey._uses.should.be.bignumber.equal(3);
  });

  it("assignKey updates both keys for correct params (merge, infinite recipient and _owner _uses) and emits event", async () => {
    const [_assignable, _expiration, _uses] = [true, time + 5 * hour, 0];
    await instance.grantKey_(_id, _owner, _assignable, _expiration, _uses);
    await instance.grantKey_(_id, accounts[1], false, time + 4 * hour, 0);

    // recipient key
    let recipientKey = key(await instance.keys(_id, accounts[1]));
    expect(recipientKey.exists).to.equal(
      true,
      "recipient key should exist at the begining"
    );
    expect(recipientKey.assignable).to.equal(
      false,
      "recipient should be not _assignable at the begining"
    );
    recipientKey.expiration.should.be.bignumber.equal(
      time + 4 * hour,
      "recipient key should have correct _expiration at the begining"
    );
    recipientKey.uses.should.be.bignumber.equal(
      0,
      "recipient key should have correct _uses at the begining"
    );

    const tx = await instance.assignKey(
      _id,
      accounts[1],
      false,
      time + 4 * hour,
      0
    );

    // _owner key
    const ownerKey = key(await instance.keys(_id, _owner));
    expect(ownerKey.exists).to.equal(true, "_owner key should still exist");
    expect(ownerKey.assignable).to.equal(
      true,
      "_owner key should still be _assignable"
    );
    ownerKey.expiration.should.be.bignumber.equal(
      _expiration,
      "_owner key should still have the same _expiration"
    );
    ownerKey.uses.should.be.bignumber.equal(
      0,
      "_owner key should still have infinite _uses"
    );

    // recipient key
    recipientKey = key(await instance.keys(_id, accounts[1]));
    expect(recipientKey.exists).to.equal(
      true,
      "recipient key should still exist"
    );
    expect(recipientKey.assignable).to.equal(
      false,
      "recipient should still not be _assignable"
    );
    recipientKey.expiration.should.be.bignumber.equal(
      time + 4 * hour,
      "recipient key should have correct _expiration"
    );
    recipientKey.uses.should.be.bignumber.equal(
      0,
      "recipient key should have correct _uses"
    );

    // emits event
    const AssignKey = event(tx, "AssignKey").args;
    AssignKey._id.should.be.bignumber.equal(_id);
    AssignKey._from.should.be.bignumber.equal(_owner);
    AssignKey._to.should.be.bignumber.equal(accounts[1]);
    AssignKey._assignable.should.be.equal(false);
    AssignKey._expiration.should.be.bignumber.equal(time + 4 * hour);
    AssignKey._uses.should.be.bignumber.equal(0);
  });

  it("assignKey reverts for non-existent key", async () => {
    await instance
      .assignKey(_id, accounts[1], false, 0, 0)
      .should.be.rejectedWith("revert");
  });

  it("assignKey reverts for expired _owner key", async () => {
    const [_assignable, _expiration, _uses] = [true, time + 5 * hour, 5];
    await instance.grantKey_(_id, _owner, _assignable, _expiration, _uses);
    await instance.assignKey.call(_id, accounts[1], false, time + 4 * hour, 3)
      .should.be.fulfilled;
    await forward(5 * hour);
    now().should.almost.equal(time + 5 * hour);
    await instance
      .assignKey(_id, accounts[1], false, time + 4 * hour, 3)
      .should.be.rejectedWith("revert");
  });

  it("assignKey reverts for _expiration extension", async () => {
    const [_assignable, _expiration, _uses] = [true, time + 5 * hour, 5];
    await instance.grantKey_(_id, _owner, _assignable, _expiration, _uses);
    await instance
      .assignKey(_id, accounts[1], false, time + 6 * hour, 3)
      .should.be.rejectedWith("revert");
  });

  it.skip("assignKey reverts for _expiration extension _to infinity", async () => {
    const [_assignable, _expiration, _uses] = [true, time + 5 * hour, 5];
    await instance.grantKey_(_id, _owner, _assignable, _expiration, _uses);
    await instance
      .assignKey(_id, accounts[1], false, 0, 3)
      .should.be.rejectedWith("revert");
  });

  it("assignKey reverts for _uses increase", async () => {
    const [_assignable, _expiration, _uses] = [true, time + 5 * hour, 5];
    await instance.grantKey_(_id, _owner, _assignable, _expiration, _uses);
    await instance
      .assignKey(_id, accounts[1], false, time + 4 * hour, 6)
      .should.be.rejectedWith("revert");
  });

  it.skip("assignKey reverts for _uses increase _to infinity", async () => {
    const [_assignable, _expiration, _uses] = [true, time + 5 * hour, 5];
    await instance.grantKey_(_id, _owner, _assignable, _expiration, _uses);
    await instance
      .assignKey(_id, accounts[1], false, time + 4 * hour, 0)
      .should.be.rejectedWith("revert");
  });

  it("assignKey reverts for non-_assignable key", async () => {
    const [_assignable, _expiration, _uses] = [false, time + 5 * hour, 5];
    await instance.grantKey_(_id, _owner, _assignable, _expiration, _uses);
    await instance
      .assignKey(_id, accounts[1], false, time + 4 * hour, 3)
      .should.be.rejectedWith("revert");
  });

  it("assignKey reverts for invalid merger (_expiration not equal)", async () => {
    const [_assignable, _expiration, _uses] = [true, time + 5 * hour, 5];
    await instance.grantKey_(_id, _owner, _assignable, _expiration, _uses);
    await instance.grantKey_(_id, accounts[1], false, time + 4 * hour, _uses);
    await instance
      .assignKey(_id, accounts[1], false, time + 3 * hour, 3)
      .should.be.rejectedWith("revert");
  });

  it("assignKey reverts for invalid merger (_assignable not equal)", async () => {
    const [_assignable, _expiration, _uses] = [true, time + 5 * hour, 5];
    await instance.grantKey_(_id, _owner, _assignable, _expiration, _uses);
    await instance.grantKey_(_id, accounts[1], true, time + 4 * hour, _uses);
    await instance
      .assignKey(_id, accounts[1], false, time + 4 * hour, 3)
      .should.be.rejectedWith("revert");
  });

  it("revokeKey deletes the senders key and emits event", async () => {
    const [_assignable, _expiration, _uses] = [true, time + 5 * hour, 0];
    await instance.grantKey_(_id, _owner, _assignable, _expiration, _uses);

    // _owner key
    let k = key(await instance.keys(_id, _owner));
    expect(k.exists).to.equal(true, "_owner key should exist in the begining");
    expect(k.assignable).to.equal(
      _assignable,
      "_owner key should be _assignable in the begining"
    );
    k.expiration.should.be.bignumber.equal(
      _expiration,
      "_owner key should have the correct _expiration in the begining"
    );
    k.uses.should.be.bignumber.equal(
      _uses,
      "_owner key should have the correct _uses in the begining"
    );

    const tx = await instance.revokeKey(_id);

    // _owner key
    k = key(await instance.keys(_id, _owner));
    assert.isTrue(empty(k), "key should be deleted");

    // emits event
    const RevokeKey = event(tx, "RevokeKey").args;
    RevokeKey._id.should.be.bignumber.equal(_id);
    RevokeKey._owner.should.be.bignumber.equal(_owner);
  });
});
