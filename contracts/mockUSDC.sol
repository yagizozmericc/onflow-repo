// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockUSDC is ERC20 {
    constructor() ERC20("Mock USDC", "mUSDC") {
        _mint(msg.sender, 1_000_000 * 10 ** decimals());
    }

    function decimals() public pure override returns (uint8) {
        return 6;
    }

    /// 👇 Faucet fonksiyonu: frontend'den kullanıcıya test token'ı mintlemek için
    function faucet(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
