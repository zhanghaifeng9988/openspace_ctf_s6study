// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// 导入 Foundry 的标准脚本库，提供部署脚本所需的基本功能
import "forge-std/Script.sol";
// 导入我们的 Vault 合约
import "../src/Vault.sol";

// 部署脚本合约，继承自 Foundry 的 Script 合约
contract VaultScript is Script {
    // Foundry 的测试/脚本框架中的标准设置函数
    // 用于设置测试环境，这里不需要特殊设置所以为空
    function setUp() public {
    }

    // 部署脚本的主要函数
    // 当运行 forge script 命令时会执行这个函数
    function run() public {
        // 定义测试助记词，这是 Foundry 的默认测试助记词
        // 用于生成测试账户
        string memory mnemonic = "test test test test test test test test test test test junk";
        
        // 从助记词派生出部署者账户地址
        // deriveRememberKey 是 Foundry 提供的函数
        // 参数 0 表示使用第一个派生地址
        (address deployer, ) = deriveRememberKey(mnemonic, 0);
        
        // 开始使用 deployer 账户进行交易广播
        // 这之后的所有交易都会使用这个账户签名
        vm.startBroadcast(deployer);

        // 部署 VaultLogic 合约
        // 传入密码 "0x1234" 作为构造函数参数
        VaultLogic logic = new VaultLogic(bytes32("0x1234"));
        
        // 部署 Vault 合约
        // 传入刚刚部署的 VaultLogic 合约地址作为参数
        Vault vault = new Vault(address(logic));
        
        // 打印部署的 Vault 合约地址
        // 使用 Foundry 的 console2 库进行日志输出
        console2.log("Vault deployed on %s", address(vault));

        // 向 Vault 合约存入 0.1 ETH
        // 使用 {value: 0.1 ether} 语法发送 ETH
        vault.deposite{value: 0.1 ether}();
        
        // 停止交易广播
        // 这之后将不再使用 deployer 账户签名交易
        vm.stopBroadcast();
    }
}
