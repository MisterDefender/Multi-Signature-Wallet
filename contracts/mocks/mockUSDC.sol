// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract USDC is ERC20 {
    constructor() ERC20("MockUSDC", "USDC") {}

    function getMockToken(uint256 amount) external {
        _mint(msg.sender, amount);
    }
}
