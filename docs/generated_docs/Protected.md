# Protected
[see the source](git+https://github.com/daostack/access_control/tree/master/contracts/Protected.sol)
> Protected


**Execution cost**: less than 518 gas

**Deployment cost**: less than 486200 gas

**Combined cost**: less than 486718 gas


## Events
### AssignKey(bytes32,address,address,bool,uint256,uint256)


**Execution cost**: No bound available


Params:

1. **_id** *of type `bytes32`*
2. **_from** *of type `address`*
3. **_to** *of type `address`*
4. **_assignable** *of type `bool`*
5. **_expiration** *of type `uint256`*
6. **_uses** *of type `uint256`*

---
### RevokeKey(bytes32,address)


**Execution cost**: No bound available


Params:

1. **_id** *of type `bytes32`*
2. **_owner** *of type `address`*


## Methods
### assignFullKey(bytes32,address)
>
> transfer all capabilities from the sender to an account


**Execution cost**: No bound available


Params:

1. **_id** *of type `bytes32`*

    > lock id

2. **_to** *of type `address`*

    > recipient



---
### assignKey(bytes32,address,bool,uint256,uint256)
>
> transfer partial or all capabilities from the sender to an account


**Execution cost**: No bound available


Params:

1. **_id** *of type `bytes32`*

    > lock id

2. **_to** *of type `address`*

    > recipient

3. **_assignable** *of type `bool`*

    > can the recipient further assignKey capabilities to other accounts?

4. **_expiration** *of type `uint256`*

    > the key's expiration time (block timestamp)

5. **_uses** *of type `uint256`*

    > number of times this key can be used (in `unlock(..)`)



---
### isValidExpiration(uint256)
>
> is the current block timestamp less than `_expiration`


**Execution cost**: less than 283 gas

**Attributes**: constant


Params:

1. **_expiration** *of type `uint256`*

    > expiration block timestamp


Returns:

> is the expiration valid

1. **valid** *of type `bool`*

---
### keys(bytes32,address)


**Execution cost**: less than 1156 gas

**Attributes**: constant


Params:

1. **param_0** *of type `bytes32`*
2. **param_1** *of type `address`*

Returns:


1. **exists** *of type `bool`*
2. **assignable** *of type `bool`*
3. **expiration** *of type `uint256`*
4. **uses** *of type `uint256`*

---
### revokeKey(bytes32)
>
> revoke the sender's key


**Execution cost**: less than 32219 gas


Params:

1. **_id** *of type `bytes32`*

    > lock id



---
### unlockable(bytes32,address)
>
> does the owner have a valid key for the lock id


**Execution cost**: less than 1602 gas

**Attributes**: constant


Params:

1. **_id** *of type `bytes32`*

    > lock id

2. **_owner** *of type `address`*

    > owner address


Returns:


1. **output_0** *of type `bool`*

[Back to the top ↑](#protected)
