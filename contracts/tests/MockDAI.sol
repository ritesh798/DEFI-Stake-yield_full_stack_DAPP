//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/Erc20/ERC20.sol";

contract MockDAI is ERC20 {
    constructor() public ERC20("Mock DAI","DAI"){
        
    }

}
