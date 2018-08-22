# Announcing DAOstack Access Control
DAOstack Access Control is a capability based security mechanism for Ethereum smart contracts that allows the developer to simply define complex role based/ordering/timing constraints for accessing the functionality of the contract.

## What is capability based security?
Capability based security makes an explicit analogy between how physical items are secured and how computer security should be done. In the physical world, restricting access to a resource means putting some kind of lock on it and distributing keys to authorized agents. Having the capability to access some resource means possessing a key that opens the resource's lock. A key (heh…) property of this approach is that keys can't be forged by an unauthorized agent.

In the context of the blockchain, we treat contract's methods as the resources under protection and we can code up the rules that ensure the above property. 
Quick example
Let's look at a simple example of using the Permissioned base contract to take advantage of access control.
```
contract Example is Permissioned {
}
```

## Its ERC165 compatible
Making Permissioned ERC165 compatible means that clients (both contracts and DApps) can programmatically check if a contract is Permissioned.

## We made an EIP
Looking at the Ethereum ecosystem we see a lot of standards that emerge and makes developing DApps efficient and easy. When talking about access control, we have some attempts to standardize various small aspects of like Ownable, ERC1261 etc. We believe we can do much better and standardize up to 95% of the use cases under a single interface specification. This will allow much greater flexibility, interoperability and standard tooling support.

Take a look at the specification [here](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-TBD.md).

## Roadmap

