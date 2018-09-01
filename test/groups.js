const Dummy = artifacts.require("./test/Dummy.sol");
const FixedGroup = artifacts.require("./FixedGroup.sol");
const UnionGroup = artifacts.require("./UnionGroup.sol");
const IntersectionGroup = artifacts.require("./IntersectionGroup.sol");
const InverseGroup = artifacts.require("./InverseGroup.sol");

const abiDecoder = require('abi-decoder');

const {
    key,
    empty,
    event,
    forward,
    now,
    hour,
    TIME_TOLERANCE
} = require("./utils");

const BigNumber = web3.BigNumber;
require("chai")
  .use(require("chai-bignumber")(BigNumber))
  .use(require("chai-as-promised"))
  .use(require("chai-almost")(TIME_TOLERANCE))
  .should();

contract('Groups', (accounts) => {

    abiDecoder.addABI(Dummy.abi);
    abiDecoder.addABI(FixedGroup.abi);

    let dummy;
    beforeEach(async () => {
        dummy = await Dummy.new();
    })

    it('(FixedGroup) should accept list of members and only allow those to forward', async () => {
        const group = await FixedGroup.new([accounts[0],accounts[1]]);
        const calldata = dummy.func.request(1,2).params[0].data;
        const { receipt } = await group.forward(dummy.address, calldata);
        const logs = abiDecoder.decodeLogs(receipt.logs);
        expect(logs.length).to.equal(1);
        const event = logs[0];
        expect(event).to.deep.equal({
            name: 'Funced',
            events: [{name: '_arg0', type:'uint256' ,value: '1'},{name: '_arg1', type:'uint256' ,value: '2'}],
            address: dummy.address,
        });
        await group.forward(dummy.address, calldata, {from: accounts[2]}).should.be.rejectedWith("revert");
    })

    it('(InverseGroup) should accept a group and only allow non-members to forward', async () => {
        let group = await FixedGroup.new([accounts[0],accounts[1]]);
        group = await InverseGroup.new(group.address);
        const calldata = dummy.func.request(1,2).params[0].data;
        const { receipt } = await group.forward(dummy.address, calldata, {from: accounts[2]});
        const logs = abiDecoder.decodeLogs(receipt.logs);
        expect(logs.length).to.equal(1);
        const event = logs[0];
        expect(event).to.deep.equal({
            name: 'Funced',
            events: [{name: '_arg0', type:'uint256' ,value: '1'},{name: '_arg1', type:'uint256' ,value: '2'}],
            address: dummy.address,
        });
        await group.forward(dummy.address, calldata, {from: accounts[0]}).should.be.rejectedWith("revert");
        await group.forward(dummy.address, calldata, {from: accounts[1]}).should.be.rejectedWith("revert");
    })

    it('(UnionGroup) should accept a list of group and only allow members of at least one group to forward', async () => {
        const g1 = await FixedGroup.new([accounts[3],accounts[1]]);
        const g2 = await FixedGroup.new([accounts[2],accounts[3]]);
        const group = await UnionGroup.new([g1.address, g2.address]);
        const calldata = dummy.func.request(1,2).params[0].data;
        let { receipt } = await group.forward(dummy.address, calldata, {from: accounts[2]});
        let logs = abiDecoder.decodeLogs(receipt.logs);
        expect(logs.length).to.equal(1);
        let event = logs[0];
        expect(event).to.deep.equal({
            name: 'Funced',
            events: [{name: '_arg0', type:'uint256' ,value: '1'},{name: '_arg1', type:'uint256' ,value: '2'}],
            address: dummy.address,
        });
        receipt = (await group.forward(dummy.address, calldata, {from: accounts[1]})).receipt;
        logs = abiDecoder.decodeLogs(receipt.logs);
        expect(logs.length).to.equal(1);
        event = logs[0];
        expect(event).to.deep.equal({
            name: 'Funced',
            events: [{name: '_arg0', type:'uint256' ,value: '1'},{name: '_arg1', type:'uint256' ,value: '2'}],
            address: dummy.address,
        });
        await group.forward(dummy.address, calldata, {from: accounts[0]}).should.be.rejectedWith("revert");
    })

    it('(IntersectionGroup) should accept a list of group and only allow members of at all of them to forward', async () => {
        const g1 = await FixedGroup.new([accounts[3],accounts[1]]);
        const g2 = await FixedGroup.new([accounts[2],accounts[3]]);
        const group = await IntersectionGroup.new([g1.address, g2.address]);
        const calldata = dummy.func.request(1,2).params[0].data;
        const { receipt } = await group.forward(dummy.address, calldata, {from: accounts[3]});
        const logs = abiDecoder.decodeLogs(receipt.logs);
        expect(logs.length).to.equal(1);
        const event = logs[0];
        expect(event).to.deep.equal({
            name: 'Funced',
            events: [{name: '_arg0', type:'uint256' ,value: '1'},{name: '_arg1', type:'uint256' ,value: '2'}],
            address: dummy.address,
        });
        await group.forward(dummy.address, calldata, {from: accounts[1]}).should.be.rejectedWith("revert");
        await group.forward(dummy.address, calldata, {from: accounts[2]}).should.be.rejectedWith("revert");
        await group.forward(dummy.address, calldata, {from: accounts[0]}).should.be.rejectedWith("revert");
    })
})
