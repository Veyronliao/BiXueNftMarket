// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// ===== OpenZeppelin Imports =====
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "hardhat/console.sol";

/// @title ETH -> BXU Swap Contract
/// @notice 安全实现：用户发送 ETH，合约发放 BXU。
contract EthToBXUSwap is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public immutable bxuToken;
    uint256 public rate; // BXU per 1 ETH（按 token 最小单位）

    event BoughtBXU(address indexed buyer, uint256 ethAmount, uint256 bxuAmount);
    event RateChanged(uint256 oldRate, uint256 newRate);
    event WithdrawETH(address indexed to, uint256 amount);
    event WithdrawBXU(address indexed to, uint256 amount);

    /// @param _bxuToken BXU 代币地址 (ERC20)
    /// @param _rate 每 1 ETH 兑换多少 BXU（以 BXU 的最小单位计）
    constructor(IERC20 _bxuToken, uint256 _rate) Ownable(msg.sender) {
        require(address(_bxuToken) != address(0), "BXU address zero");
        require(_rate > 0, "rate zero");
        bxuToken = _bxuToken;
        rate = _rate;
    }

    /// @notice 用户购买 BXU，用 ETH 支付
    function buyBXU() external payable nonReentrant {
        require(msg.value > 0, "Send ETH to buy");

        // 计算应得 BXU 数量
        uint256 bxuAmount = (msg.value * rate) / 1 ether;
        console.log("bxuAmount:",bxuAmount);
        require(bxuAmount > 0, "Too little ETH");
        require(bxuToken.balanceOf(address(this)) >= bxuAmount, "Not enough BXU");
        console.log("contract balanceOf:",bxuToken.balanceOf(address(this)));
        // 发放 BXU
        bxuToken.transfer(msg.sender, bxuAmount);

        emit BoughtBXU(msg.sender, msg.value, bxuAmount);
    }
    /// @notice 估算发送 1 ETH 可获得多少 BXU
    function estimated(uint256 eth)external view returns(uint256){
        uint256 bxuAmount = (eth * rate) / 1 ether;
        return bxuAmount;
    }
    /// @notice 修改汇率（仅 owner）
    function setRate(uint256 newRate) external onlyOwner {
        require(newRate > 0, "rate zero");
        emit RateChanged(rate, newRate);
        rate = newRate;
    }

    /// @notice 提取收到的 ETH（仅 owner）
    function withdrawETH(address payable to, uint256 amount) external onlyOwner nonReentrant {
        require(to != address(0), "zero address");
        require(amount <= address(this).balance, "not enough ETH");
        (bool ok, ) = to.call{value: amount}("");
        require(ok, "ETH transfer failed");
        emit WithdrawETH(to, amount);
    }

    /// @notice 提取剩余 BXU（仅 owner）
    function withdrawBXU(address to, uint256 amount) external onlyOwner nonReentrant {
        require(to != address(0), "zero address");
        bxuToken.safeTransfer(to, amount);
        emit WithdrawBXU(to, amount);
    }

    /// @notice fallback: 防止误转 ETH
    receive() external payable {
        // 可选：自动触发购买逻辑
        // buyBXU();
    }
}
