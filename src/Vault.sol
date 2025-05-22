// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// haha：金库基本逻辑合约：部署时设置拥有者和密码，提供更改拥有者的方法。
contract VaultLogic {

    address public owner;

    bytes32 private password;

    // 初始化所有者和密码
    constructor(bytes32 _password) public {
        owner = msg.sender;
        password = _password;
    }

    // 更改所有者函数
    function changeOwner(bytes32 _password, address newOwner) public {
        if (password == _password) {
            owner = newOwner;
        } else {
            revert("password error");
        }
    }
}


contract Vault {

    address public owner;
    // VaultLogic 合约实例，用于代理调用
    VaultLogic logic;

    mapping (address => uint) deposites;
    // 提款开关，控制是否允许提款
    bool public canWithdraw = false;

    //初始化逻辑合约和所有者
    constructor(address _logicAddress) public {
        logic = VaultLogic(_logicAddress);
        owner = msg.sender;
    }

    // 回退函数：处理所有未匹配的函数调用
    // 使用 delegatecall 将调用转发到VaultLogic合约
    fallback() external {
        (bool result,) = address(logic).delegatecall(msg.data);
        if (result) {
            this;// 这行代码不会产生任何效果
        }
    }

    // 接收函数：处理接收 ETH 的调用
    receive() external payable {
    }

    // 存款函数：允许用户存入 ETH
    function deposite() public payable { 
        deposites[msg.sender] += msg.value;
    }


    // 如果合约余额为 0，则返回 true
    function isSolve() external view returns (bool){
        if (address(this).balance == 0) {
            return true;
        } 
    }

    // 开启提款功能
    // 只有所有者可以调用此函数
    function openWithdraw() external {
        if (owner == msg.sender) {
            canWithdraw = true;
        } else {
            revert("not owner");
        }
    }

    // 允许用户提取存款，需要满足两个条件：
    // 1. canWithdraw 为 true
    // 2. 用户有存款余额
    function withdraw() public {
        if(canWithdraw && deposites[msg.sender] >= 0) {
            (bool result,) = msg.sender.call{value: deposites[msg.sender]}("");
            if(result) {
                deposites[msg.sender] = 0;
            }
        }
    }
}