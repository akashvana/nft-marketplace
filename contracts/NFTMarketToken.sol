// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract NFTMarketToken is ERC20 {
    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {
        uint256 totalSupply = 100000 * 10 ** 18;
        uint256 halfSupply = totalSupply / 2;
        
        _mint(msg.sender, halfSupply);
        _mint(address(this), halfSupply);
    }
}
