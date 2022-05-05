// SPDX-License-Identifier: AGPL
pragma solidity ^0.7.0;

import "./lib/SafeMath.sol";
import "./ERC20.sol";
import "./Hub.sol";

contract GroupCurrencyToken is ERC20 {
    using SafeMath for uint256;

    uint8 public immutable override decimals = 18;
    uint8 public mintFeePerThousand;
    
    bool public suspended;
    
    string public name;
    string public override symbol;

    address public owner; // the safe/EOA/contract that deployed this token, can be changed by owner
    address public hub; // the address of the hub this token is associated with
    address public treasury; // account which gets the personal tokens for whatever later usage

    uint public counter;
    mapping (uint => address) public delegatedTrustees;
    
    event Minted(address indexed receiver, uint256 amount, uint256 mintAmount, uint256 mintFee);

    /// @dev modifier allowing function to be only called by the token owner
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor(address _hub, address _treasury, address _owner, uint8 _mintFeePerThousand, string memory _name, string memory _symbol) {
        symbol = _symbol;
        name = _name;
        owner = _owner;
        hub = _hub;
        treasury = _treasury;
        mintFeePerThousand = _mintFeePerThousand;
        Hub(hub).organizationSignup();
    }
    
    function suspend(bool _suspend) public onlyOwner {
        suspended = _suspend;
    }
    
    function changeOwner(address _owner) public onlyOwner {
        owner = _owner;
    }

    function addDelegatedTrustee(address _account) public onlyOwner {
        delegatedTrustees[counter] = _account;
        counter++;
    }

    function removeDelegatedTrustee(uint _index) public onlyOwner {
        delegatedTrustees[_index] = address(0);
    }

    // Group currently is created from collateral tokens, which have to be transferred to this Token before.
    // Note: This function is not restricted, so anybody can mint with the collateral Token! The function call must be transactional to be safe.
    function mint(address _collateral, uint256 _amount) public returns (uint256) {
        require(!suspended, "Minting has been suspended.");
        return transferCollateralAndMint(_collateral, _amount);
    }
    
    function transferCollateralAndMint(address _collateral, uint256 _amount) internal returns (uint256) {
        uint256 mintFee = (_amount.div(1000)).mul(mintFeePerThousand);
        uint256 mintAmount = _amount.sub(mintFee);
        // mint amount-fee to msg.sender
        _mint(msg.sender, mintAmount);
        // Token Swap, send CRC from GCTO to Treasury (has been transferred to GCTO by transferThrough)
        ERC20(_collateral).transfer(treasury, _amount);
        emit Minted(msg.sender, _amount, mintAmount, mintFee);
        return mintAmount;
    }

    function transfer(address _dst, uint256 _wad) public override returns (bool) {
        // this code shouldn't be necessary, but when it's removed the gas estimation methods
        // in the gnosis safe no longer work, still true as of solidity 7.1
        return super.transfer(_dst, _wad);
    }

    // Trust must be called by this contract (as a delegate) on Hub
    function trust(address _trustee) public {
        require(_trustee != address(0), "trustee must be valid address.");
        bool trustedByAnyDelegate = false;
        for (uint i=0; i < counter; i++) {
            if (delegatedTrustees[i] != address(0)) {
                if (HubI(hub).limits(delegatedTrustees[i], _trustee) > 0) {
                    trustedByAnyDelegate = true;
                    break;
                }
            }
        }
        require(trustedByAnyDelegate, "trustee is not trusted by any delegate.");
        Hub(hub).trust(_trustee, 100);
    }
}
