// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

import "./tax/ITaxHandler.sol";
import "./treasury/ITreasuryHandler.sol";

/**
 * @title LemaToken
 * @notice This is Lemmatron Governance Token.
 */
contract LemaToken is Initializable, ERC20Upgradeable, OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;

    uint256 private _cap;
    address public burnerAddress;
    address public lemaChefAddress;

    /// @notice The contract that performs treasury-related operations.
    ITreasuryHandler public treasuryHandler;

    /// @notice Emitted when the treasury handler contract is changed.
    event TreasuryHandlerChanged(address oldAddress, address newAddress);

    /**
     * @param _burnerAddress Address of the burner.
     * @param _treasuryHandlerAddress Address of the LemaTaxHandler contract.
     */
    function initialize(
        address _burnerAddress,
        address _treasuryHandlerAddress
    ) public initializer {
        __ERC20_init("Lema Token", "LEMA");
        __Ownable_init();
        burnerAddress = _burnerAddress;
        _cap = 1e28; //10 billion
        treasuryHandler = ITreasuryHandler(_treasuryHandlerAddress);
    }

    /**
     * @notice Get address of the owner.
     * @dev Required as per BEP20 standard.
     * @return Address of the owner.
     */
    function getOwner() external view returns (address) {
        return owner();
    }

    /**
     * @dev Returns the maximum amount of tokens that can be minted.
     */
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
     * @dev Returns the address of the lema chef.
     */
    function lemaChef() public view virtual returns (address) {
        return lemaChefAddress;
    }

    modifier onlyBurner() {
        require(msg.sender == burner(), "Need Burner !");
        _;
    }

    modifier onlyLemaChefOrOwner() {
        require(
            msg.sender == lemaChef() || msg.sender == owner(),
            "Need LemaChef or Owner !"
        );
        _;
    }

    /// @notice Updates burner address. Must only be called by the burner.
    function updateBurnerAddress(address _newBurnerAddress) public onlyBurner {
        burnerAddress = _newBurnerAddress;
    }

    /// @notice Updates lemachef address. Must only be called by the owner.
    function updateLemaChefAddress(address _newLemaChefAddress)
        public
        onlyLemaChefOrOwner
    {
        lemaChefAddress = _newLemaChefAddress;
    }

    /// @notice Updates treasury handler address. Must only be called by the owner.
    function updateTreasuryHandlerAddress(address _newTreasuryHandlerAddress)
        public
        onlyOwner
    {
        address oldTreasuryHandlerAddress = address(treasuryHandler);
        treasuryHandler = ITreasuryHandler(_newTreasuryHandlerAddress);
        emit TreasuryHandlerChanged(
            oldTreasuryHandlerAddress,
            _newTreasuryHandlerAddress
        );
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
        treasuryHandler.beforeTransferHandler(from, to, amount);

        super._transfer(from, to, amount);

        treasuryHandler.afterTransferHandler(from, to, amount);
    }
}
