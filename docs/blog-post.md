# Announcing DAOstack Access Control
DAOstack Access Control is a capability based security mechanism for Ethereum smart contracts that allows the developer to simply define complex role based/ordering/timing constraints for accessing the functionality of the contract.

## What is capability based security?
Capability based security makes an explicit analogy between how physical items are secured and how computer security should be done. In the physical world, restricting access to a resource means putting some kind of lock on it and distributing keys to authorized agents. Having the capability to access some resource means possessing a key that opens the resource's lock. A key (heh…) property of this approach is that keys can't be forged by an unauthorized agent.

In the context of the blockchain, we treat contract's methods as the resources under protection and we can code up the rules that ensure the above property.

## Quick example

Our simple example is of a company who wants to recruit employees via an external HR company and pay them our regularly each month
Let's see how we can use the `Protected` base contract and take advantage of access control to make this problem a breeze.

Start by inheriting from `Protected`:
```solidity
contract Company is Protected {
}
```

We grant the creator of the contract (presumably the CEO) the ability to manage HR companies for the company:
```solidity
constructor(address _HRCompany, address _COO) {
    // The sender has unlimited access to `manageHRCompany`
    grantFullKey("manageHRCompany", msg.sender);
    COO = _COO;
}
```

Define what it means to manage HR companies, we also give HR companies the ability to register employees:
```solidity
function hireHRCompany(address _HRCompany, uint80 n_employees)
    public
    guarentee(unlock("manageHRCompany"))
{
    // Allow the HRCompany to register up to `n_employees`
    grantKey(
        "registerEmployee",
        _HRCompany,
        false,      // not assignable to other accounts
        0,          // effective immediately
        0,          // no expiration
        n_employees // can be used up to `n_employees` times
    );
}

function fireHRCompany(address _HRCompany)
    public
    guarentee(unlock("manageHRCompany"))
{
    // Revoke access to `registerEmployee`
    revokeOwnerKey("registerEmployee", _HRCompany);
}
```


At `registerEmployee`, we register the employee and grant the COO the ability to payout to this employee in a month from now.
```
function registerEmployee(address _employee, uint _salary)
    public
    guarentee(unlock("registerEmployee"))
{
    // register the employee, set last pay date to now

    // Next payday for this employee is at least a month from now
    grantKey(
        lockId("payout", _employee),
        COO,
        true,          // assignable to other accounts
        now + 30 days, // can be called in at least a month from now
        0,             // no expiration
        1              // one time use
    );
}
```

and this is what `payout` looks like:

```
function payout(address _employee)
    public
    // The sender can payout to this employee
    gurentee(unlock(lockId("payout", _employee)))
{
    // payout for the duration from last pay date...

    // Next payday is at least a month from now
    grantKey(
        lockId("payout", _employee),
        COO,
        true,          // assignable to other accounts
        now + 30 days, // can be called in at least a month from now
        0,             // no expiration
        1              // one time use
    );
}
```

Take a look at the full example [here](https://github.com/daostack/access_control/tree/master/contracts/examples/Company.sol).

## Its ERC165 compatible
Making Permissioned ERC165 compatible means that clients (both contracts and DApps) can programmatically check if a contract is Permissioned.

## We made an EIP
Looking at the Ethereum ecosystem we see a lot of standards that emerge and makes developing DApps efficient and easy. When talking about access control, we have some attempts to standardize various small aspects of like Ownable, ERC1261 etc. We believe we can do much better and standardize up to 95% of the use cases under a single interface specification. This will allow much greater flexibility, interoperability and standard tooling support.

Take a look at the specification [here](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-TBD.md).

## Roadmap

