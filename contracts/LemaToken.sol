// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

// This is Lemmatron Governance Token
contract LemaToken is Initializable, ERC20Upgradeable, OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;

    uint256 private _cap;
    address public burnerAddress;
    address public lemaChefAddress;
    address public treasuryAddress;
    uint256 public taxRate; // in percentage, 10000 = 100%

    function initialize(address _burnerAddress, address _treasuryAddress) public initializer {
        __ERC20_init("Lema Token", "LEMA");
        __Ownable_init();
        burnerAddress = _burnerAddress;
        _cap = 1e28; //10 billion
        treasuryAddress = _treasuryAddress;
    }

    function getOwner() external view returns (address) {
        return owner();
    }

    function cap() public view virtual returns (uint256) {
        return _cap;
    }

    /**
     * @dev Returns the address of the burner.
     */
    function burner() public view virtual returns (address) {
        return burnerAddress;
    }

    /**
     * @dev Returns the address of the nen chef.
     */
    function lemaChef() public view virtual returns (address) {
        return lemaChefAddress;
    }

    modifier onlyBurner() {
        require(msg.sender == burner(), "Need Burner !");
        _;
    }

    // modifier onlyOwner() {
    //     require(msg.sender == owner, "Need Burner !");
    //     _;
    // }

    modifier onlyLemaChefOrOwner() {
        require(
            msg.sender == lemaChef() || msg.sender == owner(),
            "Need LemaChef or Owner !"
        );
        _;
    }

    // update burner address, can only be updated by current burner
    function updateBurnerAddress(address _newBurnerAddress) public onlyBurner {
        burnerAddress = _newBurnerAddress;
    }

    // update lemachef address, can only be updated by owner
    function updateLemaChefAddress(address _newLemaChefAddress)
        public
        onlyLemaChefOrOwner
    {
        lemaChefAddress = _newLemaChefAddress;
    }

    // update tax rate, can only be updated by owner
    function updateTaxRate(uint256 _taxRate)
        public
        onlyLemaChefOrOwner
    {
        require(_taxRate >= 0 && _taxRate <= 10000, "Tax rate must be greater than 0 and less than 10000");
        taxRate = _taxRate;
    }
    
    // update treasury address, can only be updated by owner
    function updateTreauryAddress(address _newTreasuryAddress)
        public
        onlyLemaChefOrOwner
    {
        treasuryAddress = _newTreasuryAddress;
    }

    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner.
    function mint(address _to, uint256 _amount) public onlyOwner {
        require(totalSupply().add(_amount) <= cap(), "LemaToken: Cap exceeded");
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) public onlyBurner {
        _burn(_from, _amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        uint taxAmount = amount.mul(taxRate).div(10000);
        super._transfer(from, treasuryAddress, taxAmount);
        super._transfer(from, to, amount.sub(taxAmount));
    }
}
