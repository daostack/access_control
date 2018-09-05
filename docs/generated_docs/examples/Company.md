# Company
[see the source](git+https://github.com/daostack/access_control/tree/master/contracts/examples/Company.sol)


**Execution cost**: No bound available

**Deployment cost**: less than 1050600 gas

**Combined cost**: No bound available

## Constructor



Params:

1. **_COO** *of type `address`*

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
### registerEmployee(address,uint256)


**Execution cost**: No bound available


Params:

1. **_employee** *of type `address`*
2. **_salary** *of type `uint256`*


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
### fireHRCompany(address)


**Execution cost**: No bound available


Params:

1. **_HRCompany** *of type `address`*


--- 
### isValidExpiration(uint256)
>
> is the current block timestamp less than `_expiration`


**Execution cost**: less than 340 gas

**Attributes**: constant


Params:

1. **_expiration** *of type `uint256`*

    > expiration block timestamp


Returns:

> is the expiration valid

1. **valid** *of type `bool`*

--- 
### payout(address)


**Execution cost**: No bound available


Params:

1. **_employee** *of type `address`*


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
### hireHRCompany(address,uint80)


**Execution cost**: No bound available


Params:

1. **_HRCompany** *of type `address`*
2. **n_employees** *of type `uint80`*


--- 
### getKey(bytes32,address)
>
> does the owner have a valid key for the lock id


**Execution cost**: less than 1640 gas

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
### unlockable(bytes32,address)
>
> does the owner have a valid key for the lock id


**Execution cost**: less than 1945 gas

**Attributes**: constant


Params:

1. **_id** *of type `bytes32`*

    > lock id

2. **_owner** *of type `address`*

    > owner address


Returns:


1. **output_0** *of type `bool`*

[Back to the top ↑](#company)
