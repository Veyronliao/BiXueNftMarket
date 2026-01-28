const { ethers } = require("hardhat");

async function main() {
    const [account1, account2] = await ethers.getSigners();
    //deploy nft
    // console.log("deploying nft contract...");
    // console.log("deployer address:",account1.address);
    // const nftFactory=await ethers.getContractFactory("VeyronNft");
    // const nft=await nftFactory.deploy();
    // await nft.waitForDeployment();//ethers v6
    // //await nft.deployed(); ethers v5
    // console.log("nft contract address:",nft.getAddress());
    //部署nft
    const NFT = await ethers.getContractFactory("BiXueNft");
    // 部署合约（传构造函数参数就放在这里）
    const nft = await NFT.deploy();
    // 等待部署完成（Ethers v6 的正确写法）
    await nft.waitForDeployment();
    // 获取nft合约地址
    const nftAddress = await nft.getAddress();
    console.log("nft contract address:",nftAddress);
    //部署usdt
    const usdtfactory = await ethers.getContractFactory("BiXueUSDT");
    // 部署usdt合约
    const usdt = await usdtfactory.deploy();
    // 等待部署完成（Ethers v6 的正确写法）
    await usdt.waitForDeployment();
    // 获取usdt合约地址
    const usdtAddress = await usdt.getAddress();
    console.log("usdt contract address:",usdtAddress);
    //部署nftmarket
    const marketfactory = await ethers.getContractFactory("BiXueNftMarket");
    const market = await marketfactory.deploy(usdtAddress,nftAddress);
    await market.waitForDeployment();
    const marketAddress = await market.getAddress();
    console.log("nftmarket contract address:",marketAddress);
    //部署swap合约
    const EthToBxuSwapFactory = await ethers.getContractFactory("EthToBXUSwap");
    //const ethToBxuSwap = await EthToBxuSwapFactory.deploy(usdtAddress,0.001*1e18);
    const ethToBxuSwap = await EthToBxuSwapFactory.deploy(usdtAddress,ethers.parseUnits("200000", 18));
    await ethToBxuSwap.waitForDeployment();
    const ethToBxuSwapAddress = await ethToBxuSwap.getAddress();
    //授权swap合约可以从部署者地址转出一定数量的usdt
    const approveTx = await usdt.transfer(ethToBxuSwapAddress, ethers.parseUnits("1000000", 18));
    await approveTx.wait();
    console.log("EthToBxuSwap contract address:",ethToBxuSwapAddress);
}
main().then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
