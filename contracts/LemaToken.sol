// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "./utils/Pausable.sol";

import "./tax/ITaxHandler.sol";
import "./treasury/ITreasuryHandler.sol";

/**
 * @title LemaToken
 * @notice This is Lemmatron Governance Token.
 */
contract LemaToken is
    Initializable,
    ERC20Upgradeable,
    OwnableUpgradeable,
    Pausable
{
    using SafeMathUpgradeable for uint256;

    uint256 private _cap;
    address public burnerAddress;
    address public lemaChefAddress;

    /// @notice The contract that performs treasury-related operations.
    ITreasuryHandler public treasuryHandler;

    /// @notice The contract that performs tax-related operations.
    ITaxHandler public taxHandler;

    /// @notice Emitted when the treasury handler contract is changed.
    event TreasuryHandlerChanged(address oldAddress, address newAddress);

    /// @notice Emitted when the treasury handler contract is changed.
    event TaxHandlerChanged(address oldAddress, address newAddress);

    /**
     * @param _burnerAddress Address of the burner.
     * @param _treasuryHandlerAddress Address of the LemaTaxHandler contract.
     */
    function initialize(
        address _burnerAddress,
        address _treasuryHandlerAddress,
        address _taxHandlerAddress
    ) public initializer {
        __ERC20_init("Lema Token", "LEMA");
        __Ownable_init();
        __PausableUpgradeable_init();
        burnerAddress = _burnerAddress;
        _cap = 1e28; //10 billion
        treasuryHandler = ITreasuryHandler(_treasuryHandlerAddress);
        taxHandler = ITaxHandler(_taxHandlerAddress);
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

    /// @notice Updates tax handler address. Must only be called by the owner.
    function updateTaxHandlerAddress(address _newTaxHandlerAddress)
        public
        onlyOwner
    {
        address oldTaxHandlerAddress = address(taxHandler);
        taxHandler = ITaxHandler(_newTaxHandlerAddress);
        emit TaxHandlerChanged(oldTaxHandlerAddress, _newTaxHandlerAddress);
    }

    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner.
    function mint(address _to, uint256 _amount) public onlyOwner whenNotPaused {
        require(totalSupply().add(_amount) <= cap(), "LemaToken: Cap exceeded");
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount)
        public
        onlyBurner
        whenNotPaused
    {
        _burn(_from, _amount);
    }

    /**
     * @notice Transfer tokens from caller's address to another.
     * @param recipient Address to send the caller's tokens to.
     * @param amount The number of tokens to transfer to recipient.
     * @return True if transfer succeeds, else an error is raised.
     */
    function transfer(address recipient, uint256 amount)
        public
        override
        whenNotPaused
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override whenNotPaused returns (bool) {
        super._spendAllowance(from, _msgSender(), amount);
        _transfer(from, to, amount);
        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        treasuryHandler.beforeTransferHandler(from, to, amount);

        uint256 tax = taxHandler.getTax(from, to, amount);
        uint256 taxedAmount = amount - tax;

        super._transfer(from, to, taxedAmount);

        if (tax > 0) {
            super._transfer(from, address(treasuryHandler), tax);
        }

        treasuryHandler.afterTransferHandler(from, to, amount);
        emit Transfer(from, to, taxedAmount);
    }
}
