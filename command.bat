=======================================================================================
添加sepolia测试网到metamask钱包：
网络名称：Sepolia Test Network
新RPC URL：https://sepolia.infura.io/v3/YOUR_INFURA_PROJECT_ID
链ID：11155111
货币符号：ETH
区块浏览器URL：https://sepolia.etherscan.io

=======================================================================================
#1、remixd 连接本地项目到 remix ide,快速部署并测试
#安装remixd
npm install -g @remix-project/remixd
# 启动命令
# 其中-s 后面是本地项目路径，--remix-ide 或 -
以管理员打开cmd
cd K:\hardhat-project(确保remix中项目文件在一个根节点下面,否则连接不上本地文件)
remixd -s . --remix-ide https://remix.ethereum.org
# 启动hardhat本地测试网络,并允许外部连接
npx hardhat node --hostname 0.0.0.0
=======================================================================================
# 2、安装导出abi插件
npm install hardhat-abi-exporter --save-dev

# 在hardhat.config.js 中引入require('hardhat-abi-exporter') & add config,如下：
abiExporter: { 
    path: './abi', //导出路径
    clear: true, //是否清除之前的导出文件   
    flat: true, //是否将所有abi文件导出到同一目录
    only: [], //只导出指定合约的abi
    except: ['Migrations'], //排除指定合约  
}
=======================================================================================
创建hardhat项目：
npm init -y
npm install --save-dev hardhat
npx hardhat --init
=======================================================================================
#执行导出命令
npx hardhat export-abi
=======================================================================================
# 3、扁平化合约
# 在contract目录下创建flat目录
npx hardhat flatten contracts/nft-market.sol > contracts/flat/nft-market-flat.sol
=======================================================================================
# 4、运行测试脚本
npx hardhat test
=======================================================================================
#5、编译合约
npx hardhat compile
=======================================================================================
## 6、部署合约
npx hardhat run scripts/deploy.js --network rinkeby
=======================================================================================
# 7、验证合约
npx hardhat verify --network rinkeby <DEPLOYED_CONTRACT_ADDRESS> <CONSTRUCTOR_ARGUMENTS>
=======================================================================================
# 8、查看合约   
npx hardhat console --network rinkeby
=======================================================================================
# 9、启动到本地测试网络
npx hardhat node
=======================================================================================
# 10、在本地测试网络上部署合约  
npx hardhat run scripts/deploy.js --network localhost
=======================================================================================
# 11、在本地测试网络上运行测试脚本
npx hardhat test --network localhost
=======================================================================================
# 12、在本地测试网络上运行测试脚本，并指定测试文件
npx hardhat test test/market.js --network localhost
=======================================================================================
# 13、在本地测试网络上运行测试脚本，并指定测试文件中的某个测试用例
npx hardhat test test/market.js --network localhost --grep "create order"
=======================================================================================
# 14、清理缓存和编译文件
npx hardhat clean
=======================================================================================
# 15、查看合约gas消耗
npx hardhat test --network localhost --gas-report
=======================================================================================
# 16、安装chai
npm install --save-dev chai
=======================================================================================
# 17、安装ethers
npm install --save-dev @nomiclabs/hardhat-ethers ethers
=======================================================================================
# 18、安装指定版本的harhhat
npm install --save-dev hardhat@^2.12.7
npm install --save-dev hardhat@2.14.0
=======================================================================================
# 19、安装指定版本的solidity编译器
npm install --save-dev @nomiclabs/hardhat-solhint@^3.0.1
=======================================================================================
# 20、安装solhint代码检查工具
npm install --save-dev solhint@^3.3.7 solhint-plugin-prettier@^3.1.1 solhint-config-prettier@^3.1.1
=======================================================================================
# 21、安装prettier代码格式化工具
npm install --save-dev prettier@^2.8.4
=======================================================================================
# 22、安装dotenv管理环境变量
npm install --save-dev dotenv@^16.0.3
=======================================================================================
# 23、安装etherscan验证插件
npm install --save-dev @nomiclabs/hardhat-etherscan@^3.1.5
=======================================================================================
# 24、安装web3
npm install --save-dev web3@^1.8.0
=======================================================================================
# 25、安装openzeppelin合约库
npm install --save-dev @openzeppelin/contracts@^4.7.3
=======================================================================================
# 26、安装hardhat-waffle
npm install --save-dev @nomiclabs/hardhat-waffle@^2.0.3
=======================================================================================
# 27、安装chai-as-promised
npm install --save-dev chai-as-promised@^7.1.1
=======================================================================================
# 28、安装ethereum-waffle
npm install --save-dev ethereum-waffle@^3.4.0
=======================================================================================
# 29、安装hardhat-gas-reporter
npm install --save-dev hardhat-gas-reporter@^1.0.9
=======================================================================================
# 30、安装solidity-coverage
npm install --save-dev solidity-coverage@^0.7.21
# 31、安装@openzeppelin/test-helpers
npm install --save-dev @openzeppelin/test-helpers@^0.5.15
=======================================================================================
# 32、安装@openzeppelin/test-environment
npm install --save-dev @openzeppelin/test-environment@^0.1.4    

# 查看openzeppelin版本
npm list @openzeppelin/contracts


# 使用本地主机网络部署合约失败报错如下：
=======================================================================================
creation of VeyronNft errored: Error occurred: missing revert data 
(action="estimateGas", data=null, reason=null, transaction={ "data": "0x608060405234801561000f5750002....
=======================================================================================
# 解决方法：
重新安装hardhat并创建项目
======================================================================================================================================================
安装ipfs:
1、下载kubo:
    wget https://dist.ipfs.tech/kubo/v0.26.0/kubo_v0.26.0_linux-amd64.tar.gz
2、解压并安装:
    tar -xvzf kubo_v0.26.0_linux-amd64.tar.gz
    cd kubo
    sudo bash install.sh
3、检验是否安装成功：
ipfs version
chushihuaipfs节点：
    ipfs init
4、ipfs跨域设置：
    ipfs config --json API.HTTPHeaders.Access-Control-Allow-Origin '["*"]'
    ipfs config --json API.HTTPHeaders.Access-Control-Allow-Methods '["PUT", "POST", "GET", "OPTIONS"]'
    ipfs config --json API.HTTPHeaders.Access-Control-Allow-Headers '["Authorization", "Content-Type"]'
5、修改ipfs监听地址，允许局域网访问：
    ipfs config Addresses.API "/ip4/0.0.0.0/tcp/5001"
    ipfs config Addresses.Gateway "/ip4/0.0.0.0/tcp/8080"
    ipfs config Addresses.API "/ip4/127.0.0.1/tcp/5001"
    ipfs config Addresses.Gateway "/ip4/127.0.0.1/tcp/8080"
5、启动ipfs节点：   ipfs daemon
6、访问webui:界面http://localhost:5001/webui

ipfs设置为系统服务：
cd /lib/systemed/system/
vim ipfs.service:
=======================================================================================
[Unit]
Descriiption=IPFS
[Service]
ExecStart=/usr/local/bin/ipfs daemon
Restart=always
User=root
Group=root
[Install]
WantedBy=multi-user.target
=======================================================================================
启动ipfs服务：
systemctl start ipfs.service
设置开机启动：  
systemctl enable ipfs.service
查看ipfs服务状态：
systemctl status ipfs.service
=======================================================================================
配置nginx:
vim /etc/nginx/conf.d/default.conf


=======================================================================================
分页改成 cursor pagination（skip 大了会炸）