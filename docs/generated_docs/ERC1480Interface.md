# ERC1480Interface

[see the source](git+https://github.com/daostack/access_control/tree/master/contracts/ERC1480Interface.sol)

**Execution cost**: No bound available

**Deployment cost**: No bound available

**Combined cost**: No bound available

## Events

### AssignKey(bytes32,address,address,bool,uint256,uint256,uint256)

**Execution cost**: No bound available

Params:

1. **\_id** _of type `bytes32`_
2. **\_from** _of type `address`_
3. **\_to** _of type `address`_
4. **\_assignable** _of type `bool`_
5. **\_start** _of type `uint256`_
6. **\_expiration** _of type `uint256`_
7. **\_uses** _of type `uint256`_

---

### RevokeKey(bytes32,address)

**Execution cost**: No bound available

Params:

1. **\_id** _of type `bytes32`_
2. **\_owner** _of type `address`_

## Methods

### assignFullKey(bytes32,address)

**Execution cost**: No bound available

Params:

1. **\_id** _of type `bytes32`_
2. **\_to** _of type `address`_

---

### assignKey(bytes32,address,bool,uint256,uint256,uint256)

**Execution cost**: No bound available

Params:

1. **\_id** _of type `bytes32`_
2. **\_to** _of type `address`_
3. **\_assignable** _of type `bool`_
4. **\_start** _of type `uint256`_
5. **\_expiration** _of type `uint256`_
6. **\_uses** _of type `uint256`_

---

### getKey(bytes32,address)

**Execution cost**: No bound available

**Attributes**: constant

Params:

1. **\_id** _of type `bytes32`_
2. **\_owner** _of type `address`_

Returns:

1. **output_0** _of type `bool`_
2. **output_1** _of type `bool`_
3. **output_2** _of type `uint256`_
4. **output_3** _of type `uint256`_
5. **output_4** _of type `uint256`_

---

### revokeKey(bytes32)

**Execution cost**: No bound available

Params:

1. **\_id** _of type `bytes32`_

---

### unlockable(bytes32,address)

**Execution cost**: No bound available

**Attributes**: constant

Params:

1. **\_id** _of type `bytes32`_
2. **\_owner** _of type `address`_

Returns:

1. **output_0** _of type `bool`_

[Back to the top ↑](#erc1480interface)