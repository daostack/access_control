# InverseGroup
[see the source](git+https://github.com/daostack/access_control/tree/master/contracts/Groups.sol)
> Group that comprises of all members not belonging to a group.


**Execution cost**: less than 20621 gas

**Deployment cost**: less than 147800 gas

**Combined cost**: less than 168421 gas

## Constructor



Params:

1. **_group** *of type `address`*



## Methods
### forward(address,bytes)
>
> Call a method on a contract in the name of the group.


**Execution cost**: No bound available

**Attributes**: payable


Params:

1. **_contract** *of type `address`*

    > contract address to call.

2. **_data** *of type `bytes`*

    > ABI encoded function call data.



--- 
### isMember(address)


**Execution cost**: No bound available

**Attributes**: constant


Params:

1. **_account** *of type `address`*

Returns:


1. **output_0** *of type `bool`*

[Back to the top ↑](#inversegroup)
