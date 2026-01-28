require("@nomicfoundation/hardhat-toolbox");
require('hardhat-abi-exporter')
/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.28",
  sourcify: {
    enabled: false
  },
  defaultNetwork: "hardhat",
  networks:{
    sepolia:{
      url:"https://sepolia.infura.io/v3/79524f38c577486e8b0f1b9090906e8c",
      accounts:["664f709bcc61654606dac0c6663b448e24e98da0e0d4a8fb19802c79d1bad49b"],
    },
    
    // ✅ 本地节点（用于 npx hardhat node）
    localhost: {
      url: "http://127.0.0.1:8545", // RPC 地址
      chainId: 31337,
      allowUnlimitedContractSize: true
    }
  },
  abiExporter: { 
    path: './abi', //导出路径
    clear: true, //是否清除之前的导出文件   
    flat: true, //是否将所有abi文件导出到同一目录
    only: [], //只导出指定合约的abi
    except: ['Migrations'], //排除指定合约  
  }
};
