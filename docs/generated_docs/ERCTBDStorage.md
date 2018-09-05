# ERCTBDStorage
[see the source](git+https://github.com/daostack/access_control/tree/master/contracts/ERCTBDStorage.sol)


**Execution cost**: No bound available

**Deployment cost**: No bound available

**Combined cost**: No bound available


## Events
### AssignKey(bytes32,address,address,bool,uint256,uint256,uint256)


**Execution cost**: No bound available


Params:

1. **_id** *of type `bytes32`*
2. **_from** *of type `address`*
3. **_to** *of type `address`*
4. **_assignable** *of type `bool`*
5. **_start** *of type `uint256`*
6. **_expiration** *of type `uint256`*
7. **_uses** *of type `uint256`*

--- 
### RevokeKey(bytes32,address)


**Execution cost**: No bound available


Params:

1. **_id** *of type `bytes32`*
2. **_owner** *of type `address`*


## Methods
### assignFullKey(bytes32,address)


**Execution cost**: No bound available


Params:

1. **_id** *of type `bytes32`*
2. **_to** *of type `address`*


--- 
### assignKey(bytes32,address,bool,uint256,uint256,uint256)


**Execution cost**: No bound available


Params:

1. **_id** *of type `bytes32`*
2. **_to** *of type `address`*
3. **_assignable** *of type `bool`*
4. **_start** *of type `uint256`*
5. **_expiration** *of type `uint256`*
6. **_uses** *of type `uint256`*


--- 
### getKey(bytes32,address)


**Execution cost**: No bound available

**Attributes**: constant


Params:

1. **_id** *of type `bytes32`*
2. **_owner** *of type `address`*

Returns:


1. **output_0** *of type `bool`*
2. **output_1** *of type `bool`*
3. **output_2** *of type `uint256`*
4. **output_3** *of type `uint256`*
5. **output_4** *of type `uint256`*

--- 
### keys(bytes32,address)


**Execution cost**: No bound available

**Attributes**: constant


Params:

1. **param_0** *of type `bytes32`*
2. **param_1** *of type `address`*

Returns:


1. **exists** *of type `bool`*
2. **assignable** *of type `bool`*
3. **start** *of type `uint256`*
4. **expiration** *of type `uint256`*
5. **uses** *of type `uint256`*

--- 
### revokeKey(bytes32)


**Execution cost**: No bound available


Params:

1. **_id** *of type `bytes32`*


--- 
### supportsInterface(bytes4)


**Execution cost**: No bound available

**Attributes**: constant


Params:

1. **_interfaceId** *of type `bytes4`*

Returns:


1. **output_0** *of type `bool`*

--- 
### unlockable(bytes32,address)


**Execution cost**: No bound available

**Attributes**: constant


Params:

1. **_id** *of type `bytes32`*
2. **_owner** *of type `address`*

Returns:


1. **output_0** *of type `bool`*

[Back to the top ↑](#erctbdstorage)
