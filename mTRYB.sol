// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract mTRYB is ERC20, Ownable {
    mapping(address => bool) public faucetUsed;

    constructor(address initialOwner)
        ERC20("Mock Turkish Lira Base", "mTRYB")
        Ownable(initialOwner)
    {}

    function faucet() external {
        require(!faucetUsed[msg.sender], "Faucet already used");
        faucetUsed[msg.sender] = true;
        _mint(msg.sender, 1000 * 1e18);
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}
