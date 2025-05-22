``` mermaid
sequenceDiagram
    participant User as 用户
    participant Vault as Vault合约
    participant Logic as VaultLogic合约
    participant ETH as ETH余额

    %% 初始化流程
    Note over Vault,Logic: 部署阶段
    Logic->>Logic: 构造函数(设置密码)
    Vault->>Vault: 构造函数(设置Logic地址)
    
    %% 存款流程
    Note over User,ETH: 存款流程
    User->>Vault: deposite() + ETH
    Vault->>Vault: 更新deposites映射
    Vault->>ETH: 接收ETH

    %% 提款流程
    Note over User,ETH: 提款流程
    User->>Vault: withdraw()
    alt canWithdraw为true 且 有存款
        Vault->>User: 发送ETH
        Vault->>Vault: 清零deposites
    end

    %% 代理调用流程
    Note over User,Logic: 代理调用流程
    User->>Vault: 调用未定义函数
    Vault->>Logic: delegatecall
    Logic-->>Vault: 返回结果
    Vault-->>User: 返回结果

    %% 更改所有者流程
    Note over User,Logic: 更改所有者流程
    User->>Vault: 调用changeOwner
    Vault->>Logic: delegatecall(changeOwner)
    alt 密码正确
        Logic->>Logic: 更新owner
    else 密码错误
        Logic-->>Vault: revert
    end
```


创建一个 MaliciousLogic 合约，其中包含一个 attack 函数
attack 函数使用 assembly 直接修改存储槽 0（owner）为调用者地址
在测试中，我们部署这个恶意合约
然后通过 Vault 合约的 fallback 函数调用恶意合约的 attack 函数
由于 fallback 函数使用 delegatecall，恶意合约的代码会在 Vault 合约的上下文中执行
这样就会直接修改 Vault 合约的 owner 变量
这个攻击利用了：
delegatecall 在调用者的上下文中执行代码
存储槽的布局（owner 在 slot 0）
直接使用 assembly 修改存储，绕过所有权限检查


你查看一下合约代码：D:\security\openspace_ctf_s6study\src\Vault.sol 你查看一下测试代码：D:\security\openspace_ctf_s6study\test\Vault.t.sol 任务：在测试用例中 testExploit 函数添加一些代码，设法取出预先部署的 Vault 合约内的所有资金。可以在 Vault.t.sol 中添加代码（这个注释的位置：// add your hacker code.
），或加入新合约，但不要修改已有代码。 
你听我说，实现逻辑是这样：
1、想要取钱，攻击合约就调用openWithdraw函数，让owner == msg.sender能够相等，两个值必须都是攻击合约的地址，
2、那攻击的突破口是利用delegatecall这个函数，将logic作为第1个参数，攻击合约的地址作为第二参数
，传入changeOwner方法中，因为delegatecall函数的上下文是在Vault合约环境，那么changeOwner方法中password的值对应的就是logic的值，此时条件匹配，就可以将onwer更换为攻击合约的地址
3、owner更换后，就可以开启提款功能；
4、然后利用重放攻击方式，可以将存款全部提取出来

``` mermaid
sequenceDiagram
    participant Test as VaultExploiter
    participant Vault as Vault Contract
    participant Logic as VaultLogic Contract
    participant Attack as VaultAttack Contract

    Note over Test: 初始化阶段
    Test->>Logic: 部署VaultLogic合约(password="0x1234")
    Test->>Vault: 部署Vault合约(logic地址)
    Test->>Vault: deposite{value: 0.1 ether}()

    Note over Test: 攻击阶段
    Test->>Vault: call(changeOwner(logic地址, player地址))
    Note over Vault: fallback函数触发
    Vault->>Logic: delegatecall(changeOwner)
    Note over Logic: 在Vault上下文中执行
    Note over Logic: password == logic地址
    Logic-->>Vault: 更改owner为player
    Vault-->>Test: 成功

    Test->>Vault: openWithdraw()
    Note over Vault: 检查owner == msg.sender
    Vault-->>Test: 开启提款功能

    Test->>Attack: 部署VaultAttack合约{value: 0.1 ether}
    Test->>Attack: attack()
    Attack->>Vault: deposite{value: 0.1 ether}()
    Note over Vault: 记录存款余额
    Attack->>Vault: withdraw()
    Note over Vault: 检查canWithdraw和余额
    Vault->>Attack: call{value: 0.1 ether}()
    Note over Attack: receive函数触发
    Attack->>Vault: withdraw() [重入]
    Note over Vault: 检查canWithdraw和余额
    Vault->>Attack: call{value: 0.1 ether}()
    Note over Attack: receive函数触发(不执行重入)

    Test->>Vault: isSolve()
    Note over Vault: 检查余额是否为0
    Vault-->>Test: true
```