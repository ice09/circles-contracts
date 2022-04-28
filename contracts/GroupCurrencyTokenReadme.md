# Group Currency Token Smart Contract

A group currency would define a number of individual Circles tokens directly or transitively (all accounts trusted by account X) as members. All of those members Circles could be used to mint the group currency.

_Note: The GroupCurrencyToken contract is WIP, non-tested, non-audited and not ready for Mainnet/production usage!_

See https://aboutcircles.com/t/suggestion-for-group-currencies/410 for further details.

## Call Flows for mint and mintDelegate

### memberMint

![flow](https://drive.google.com/uc?export=view&id=1QIYX3UM2HqW8UJGaUIH13SnADnZadb73)

### delegateMint

![flow](https://drive.google.com/uc?export=view&id=1t2mFhNWxrtlSSyn5TbGAh6-Nz4ds1AkA)

## Tech Walk-Through

The initial drafts uses manual steps to setup, deploy and test the `GroupCurrencyToken` smart contract.

* Clone circles-contract-group-currency fork: `git clone git@github.com:ice09/circles-contracts.git`
* Switch to branch `hub-v1-comp`
* Open contracts in Remix-IDE at https://remix.ethereum.org/ with *remixd*: `remixd -s $(pwd) -u https://remix.ethereum.org`
* Deploy `Hub.sol` with params `"1","1","CRC","Circles","50000000000000000000","1","1"`
* Deploy `GroupCurrencyToken.sol` with params `"0xd9145CCE52D386f254917e481eB44e9943F39138","0x0000000000000000000000000000000000000001", "0x5B38Da6a701c568545dCfcB03FcB875f56beddC4", 1, "GCT", "GCT"`
* Call `signup` on Hub contract with Remix Account 1 `0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2`: Alice Signup
	* This will deploy an individual Circles-Token from the Hub contract with Token address `0x5C9eb5D6a6C2c1B3EFc52255C0b356f116f6f66D`
* Load `Token.sol` at `0x5C9eb5D6a6C2c1B3EFc52255C0b356f116f6f66D`
	* This is the Circles-Token which will be used as Collateral Token
* Transfer with Account 1 "1000" Tokens to GCT Address `0xd9145CCE52D386f254917e481eB44e9943F39138`

### mint

* [GroupCurrencyToken] `mint(0x5C9eb5D6a6C2c1B3EFc52255C0b356f116f6f66D,1000)` with any Remix Account (**unresticted access**)

### memberMint

* [CollateralToken] `approve` GroupCurrencyToken address (eg. amount 10000000000000000000)
* [GroupCurrencyToken] `addMember` for Collateral Token address
* [GroupCurrencyToken] `mint` 10000000000000000000 for Collateral token

### delegateMint

* [CollateralToken] `approve` GroupCurrencyToken address (eg. amount 10000000000000000000)
* [Hub] `signup` with second account
* [Hub] `trust` with second account: firstAccountAddress, 100
* [GroupCurrencyToken] `addDelegateTrustee` with first account: secondAccountAddress
* [GroupCurrencyToken] `mintDelegate` with first account: secondAccountAddress, CollateralToken, 10000