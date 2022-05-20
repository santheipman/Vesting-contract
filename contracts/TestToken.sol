// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;  

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";  
import "@openzeppelin/contracts/access/Ownable.sol";  

contract TestToken is ERC20, Ownable{   
    constructor(uint256 initialAmount)  ERC20("TestToken", "TEST"){
        _mint(msg.sender, initialAmount);
    }
}