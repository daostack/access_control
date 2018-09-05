# PermissionedMock
[see the source](git+https://github.com/daostack/access_control/tree/master/contracts/test/PermissionedMock.sol)


**Execution cost**: less than 838 gas

**Deployment cost**: less than 802000 gas

**Combined cost**: less than 802838 gas


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
### revokeKey(bytes32)
>
> revoke the sender's key


**Execution cost**: less than 37300 gas


Params:

1. **_id** *of type `bytes32`*

    > lock id



--- 
### assignKey(bytes32,address,bool,uint256,uint256,uint256)
>
> assign partial or all capabilities from the sender to an account


**Execution cost**: No bound available


Params:

1. **_id** *of type `bytes32`*

    > lock id

2. **_to** *of type `address`*

    > recipient

3. **_assignable** *of type `bool`*

    > can the recipient further assignKey capabilities to other accounts?

4. **_start** *of type `uint256`*

    > the key's start time (block timestamp)

5. **_expiration** *of type `uint256`*

    > the key's expiration time (block timestamp)

6. **_uses** *of type `uint256`*

    > number of times this key can be used (in `unlock(..)`)



--- 
### assignFullKey(bytes32,address)
>
> assign all capabilities from the sender to an account


**Execution cost**: No bound available


Params:

1. **_id** *of type `bytes32`*

    > lock id

2. **_to** *of type `address`*

    > recipient



--- 
### getKey(bytes32,address)
>
> does the owner have a valid key for the lock id


**Execution cost**: less than 1662 gas

**Attributes**: constant


Params:

1. **_id** *of type `bytes32`*

    > lock id

2. **_owner** *of type `address`*

    > owner address


Returns:

> the properties of the requested key as a tuple

1. **output_0** *of type `bool`*
2. **output_1** *of type `bool`*
3. **output_2** *of type `uint256`*
4. **output_3** *of type `uint256`*
5. **output_4** *of type `uint256`*

--- 
### grantFullKey_(bytes32,address)


**Execution cost**: No bound available


Params:

1. **_id** *of type `bytes32`*
2. **_to** *of type `address`*


--- 
### grantKey_(bytes32,address,bool,uint256,uint256,uint256)


**Execution cost**: less than 84067 gas


Params:

1. **_id** *of type `bytes32`*
2. **_to** *of type `address`*
3. **_assignable** *of type `bool`*
4. **_start** *of type `uint256`*
5. **_expiration** *of type `uint256`*
6. **_uses** *of type `uint256`*


--- 
### isValidExpiration(uint256)
>
> is the current block timestamp less than `_expiration`


**Execution cost**: less than 318 gas

**Attributes**: constant


Params:

1. **_expiration** *of type `uint256`*

    > expiration block timestamp


Returns:

> is the expiration valid

1. **valid** *of type `bool`*

--- 
### keys(bytes32,address)


**Execution cost**: less than 1424 gas

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
### revokeOwnerKey_(bytes32,address)


**Execution cost**: less than 37362 gas


Params:

1. **_id** *of type `bytes32`*
2. **_owner** *of type `address`*


--- 
### supportsInterface(bytes4)
>
>Query if a contract implements an interface
>
> Interface identification is specified in ERC-165. This function  uses less than 30,000 gas.


**Execution cost**: less than 271 gas

**Attributes**: constant


Params:

1. **interfaceID** *of type `bytes4`*

    > The interface identifier, as specified in ERC-165


Returns:

> `true` if the contract implements `interfaceID` and  `interfaceID` is not 0xffffffff, `false` otherwise

1. **output_0** *of type `bool`*

--- 
### unlock_(bytes32)


**Execution cost**: No bound available


Params:

1. **_id** *of type `bytes32`*

Returns:


1. **output_0** *of type `bool`*

--- 
### unlockable(bytes32,address)
>
> does the owner have a valid key for the lock id


**Execution cost**: less than 1967 gas

**Attributes**: constant


Params:

1. **_id** *of type `bytes32`*

    > lock id

2. **_owner** *of type `address`*

    > owner address


Returns:


1. **output_0** *of type `bool`*

[Back to the top ↑](#permissionedmock)
