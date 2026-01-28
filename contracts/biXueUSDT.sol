// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract BiXueUSDT is ERC20 {
    constructor()
        ERC20("fake usdt in cbi", "BXU")    
    {
        _mint(msg.sender, 1*10**8*10**18);
        _mint(address(this), 1*10**8*10**18);
    }
}