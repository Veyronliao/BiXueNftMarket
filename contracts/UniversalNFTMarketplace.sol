// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";


contract UniversalNFTMarketplace is Ownable,ReentrancyGuard{
    using ECDSA for bytes32;
    uint96 public marketplaceFeeBps;  // e.g. 250 = 2.5%
    mapping(address => uint256) public pendingWithdrawals;
    //订单结构体
    struct Listing{
        address nftContract;
        address seller;
        uint256 tokenid;
        uint256 price;
        bool active;
    }
    //订单表
    //nftcontract=>tokenid=>listing
    mapping(address=>mapping(uint256=>Listing)) public listings;
    //事件
    event Listed(address indexed nftContract,uint256 tokenid,address indexed seller,uint256 price);
    event Cancalled(address indexed nftContract,uint256 tokenid,address indexed seller);
    event Sold(address indexed nftContract,uint256 tokenid,address indexed buyer,address seller,uint256 peice);
    //构造函数
    constructor(uint96 _marketplaceFeeBps)Ownable(msg.sender){
        require(_marketplaceFeeBps<=10000,"Fee too hight");
        marketplaceFeeBps=_marketplaceFeeBps;
    }
    //上架nft
    function listNFT(address nftContract,uint256 tokenid,uint256 price)external {
        require(nftContract!=address(0),"invalid nftcontract address");
        require(price>0,"invalid price");
        //erc721实例
        IERC721 nft=IERC721(nftContract);
        //获取owner
        address owner=nft.ownerOf(tokenid);
        require(owner==msg.sender,"not owner");
        //检查是否已经授权给marketplace
        require(
            nft.getApproved(tokenid)==address(this)||
            nft.isApprovedForAll(owner,address(this)),
            "Market not approved"
        );
        Listing memory list=Listing({
            nftContract:nftContract,
            seller:msg.sender,
            tokenid:tokenid,
            price:price,
            active:true
        });
        listings[nftContract][tokenid]=list;
        //listings[nftContract]=mapping[tokenid]{list};
        emit Listed(nftContract,tokenid,msg.sender,price);
    }
    function cancelListing(address nftContract, uint256 tokenId) external {
        Listing storage l = listings[nftContract][tokenId];
        require(l.active, "Not listed");
        require(msg.sender == l.seller || msg.sender == owner(), "Not seller");

        delete listings[nftContract][tokenId];

        emit Cancalled(nftContract, tokenId, l.seller);
    }

    /* ========== BUY ========== */

    function buyNFT(address nftContract, uint256 tokenId)
        external
        payable
        nonReentrant
    {
        Listing memory l = listings[nftContract][tokenId];
        require(l.active, "Not listed");
        require(msg.value >= l.price, "Not enough ETH");

        delete listings[nftContract][tokenId];

        IERC721 nft = IERC721(nftContract);

        // 验证 seller 仍然是 owner
        require(nft.ownerOf(tokenId) == l.seller, "Seller not owner anymore");

        // 平台手续费
        uint256 platformFee = (l.price * marketplaceFeeBps) / 10000;

        // 处理版税 EIP-2981
        uint256 royaltyAmount = 0;
        address royaltyReceiver = address(0);

        if (_supportsRoyalty(nftContract)) {
            (royaltyReceiver, royaltyAmount) = IERC2981(nftContract)
                .royaltyInfo(tokenId, l.price);
        }

        uint256 sellerAmount = l.price;

        // 扣平台费
        if (platformFee > 0) {
            sellerAmount -= platformFee;
            _asyncTransfer(owner(), platformFee);
        }

        // 扣版权税
        if (royaltyAmount > 0 && royaltyReceiver != address(0)) {
            royaltyAmount = royaltyAmount > sellerAmount ? sellerAmount : royaltyAmount;
            sellerAmount -= royaltyAmount;
            _asyncTransfer(royaltyReceiver, royaltyAmount);
        }

        // 卖家收益
        _asyncTransfer(l.seller, sellerAmount);

        // 超额退款
        if (msg.value > l.price) {
            payable(msg.sender).transfer(msg.value - l.price);
        }

        // 转移 NFT
        nft.safeTransferFrom(l.seller, msg.sender, tokenId);

        emit Sold(nftContract, tokenId, msg.sender, l.seller, l.price);
    }

    /* ========== VIEW FUNCTIONS ========== */

    function getListing(address nftContract, uint256 tokenId)
        external
        view
        returns (Listing memory)
    {
        return listings[nftContract][tokenId];
    }

    /* ========== ADMIN ========== */

    function setMarketplaceFee(uint96 newFeeBps) external onlyOwner {
        require(newFeeBps <= 10000, "max 100%");
        marketplaceFeeBps = newFeeBps;
    }

    /* ========== INTERNAL ========== */

    function _supportsRoyalty(address nft)
        internal
        view
        returns (bool)
    {
        try IERC165(nft).supportsInterface(type(IERC2981).interfaceId) returns (bool ok) {
            return ok;
        } catch {
            return false;
        }
    }
    function withdraw() external 
    {
        uint256 amount = pendingWithdrawals[msg.sender];
        require(amount > 0, "Nothing to withdraw");
        pendingWithdrawals[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "ETH transfer failed");
    }
    function _asyncTransfer(address to, uint256 amount) internal {
        pendingWithdrawals[to] += amount;
    }
    receive() external payable {}
    fallback() external payable {}
}
