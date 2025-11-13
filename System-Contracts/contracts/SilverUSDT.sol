// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title SilverUSDT
 * @dev USDT-like stablecoin for SilverBitcoin blockchain
 * Features:
 * - Pausable: Can pause all transfers in emergency
 * - Burnable: Tokens can be burned
 * - Blacklist: Can blacklist addresses
 * - Mintable: Owner can mint new tokens
 * - 6 decimals (like USDT)
 */
contract SilverUSDT is ERC20, ERC20Burnable, Pausable, Ownable {
    
    // Blacklist mapping
    mapping(address => bool) private _blacklisted;
    
    // Events
    event Blacklisted(address indexed account);
    event UnBlacklisted(address indexed account);
    event Mint(address indexed to, uint256 amount);
    
    /**
     * @dev Constructor
     * @param initialSupply Initial token supply (in tokens, not wei)
     */
    constructor(uint256 initialSupply) ERC20("Silver USDT", "sUSDT") {
        _mint(msg.sender, initialSupply * 10**decimals());
    }
    
    /**
     * @dev Returns 6 decimals (like USDT)
     */
    function decimals() public pure override returns (uint8) {
        return 6;
    }
    
    /**
     * @dev Mint new tokens (only owner)
     * @param to Address to mint tokens to
     * @param amount Amount of tokens to mint (in tokens, not wei)
     */
    function mint(address to, uint256 amount) external onlyOwner {
        require(to != address(0), "Cannot mint to zero address");
        require(!_blacklisted[to], "Cannot mint to blacklisted address");
        
        uint256 mintAmount = amount * 10**decimals();
        _mint(to, mintAmount);
        
        emit Mint(to, mintAmount);
    }
    
    /**
     * @dev Pause all token transfers (only owner)
     */
    function pause() external onlyOwner {
        _pause();
    }
    
    /**
     * @dev Unpause token transfers (only owner)
     */
    function unpause() external onlyOwner {
        _unpause();
    }
    
    /**
     * @dev Add address to blacklist (only owner)
     * @param account Address to blacklist
     */
    function blacklist(address account) external onlyOwner {
        require(account != address(0), "Cannot blacklist zero address");
        require(!_blacklisted[account], "Address already blacklisted");
        
        _blacklisted[account] = true;
        emit Blacklisted(account);
    }
    
    /**
     * @dev Remove address from blacklist (only owner)
     * @param account Address to remove from blacklist
     */
    function unBlacklist(address account) external onlyOwner {
        require(_blacklisted[account], "Address not blacklisted");
        
        _blacklisted[account] = false;
        emit UnBlacklisted(account);
    }
    
    /**
     * @dev Check if address is blacklisted
     * @param account Address to check
     */
    function isBlacklisted(address account) external view returns (bool) {
        return _blacklisted[account];
    }
    
    /**
     * @dev Hook that is called before any transfer of tokens
     * Checks for pause and blacklist
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        require(!_blacklisted[from], "Sender is blacklisted");
        require(!_blacklisted[to], "Recipient is blacklisted");
        
        super._beforeTokenTransfer(from, to, amount);
    }
}
