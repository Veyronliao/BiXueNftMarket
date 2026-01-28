// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "hardhat/console.sol";
struct Order {
    address seller;
    uint256 tokenId;
    uint256 price;
}

contract BiXueNftMarket {
    //erc20合约地址（作为货币用于买卖nft）
    IERC20 public erc20;
    //erc721合约地址(铸造nft的合约)
    IERC721 public erc721;
    //onERC721Received函数返回值
    bytes4 internal constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;
    mapping(uint256 => Order) public orderOfId; //token id to order
    Order[] public orders;
    mapping(uint256 => uint256) public idToOrderIndex; //token id to index in orders
    //交易nft事件
    event Deal(address seller, address buyer, uint256 tokenId, uint256 price);
    //新订单事件
    event NewOrder(address seller, uint256 tokenId, uint256 price);
    //修改价格事件
    event PriceChange(
        address seller,
        uint256 tokenId,
        uint256 previousPrice,
        uint256 newPrice
    );
    //取消订单事件
    event OrderCancelled(address seller, uint256 tokenId);

    //初始化合约
    constructor(address _erc20, address _erc721) {
        require(_erc20 != address(0), "zero erc20 address");
        require(_erc721 != address(0), "zero erc721 address");
        erc20 = IERC20(_erc20);
        erc721 = IERC721(_erc721);
    }

    error OrderNotExists();
    error CanNotBuyOwnNFT();
    error NFTNotInMarket();
    error ERC20TransferFailed();
    error NotApprovedEnough();
    //购买nft
    function buy(uint256 _tokenId) external {
        //address seller = orderOfId[_tokenId].seller;
        // address buyer = msg.sender;//gas优化点：多余代码
        // uint256 price = orderOfId[_tokenId].price;
        Order memory orderItem = orderOfId[_tokenId];
        uint256 price = orderOfId[_tokenId].price;
        address seller = orderItem.seller;
        //require(seller != address(0), "order not exists");//gas优化点：改用自定义错误
        if (seller == address(0)) {
            revert OrderNotExists();
        }
        //require(seller != msg.sender, "can not buy your own nft");//gas优化点：改用自定义错误
        if (seller == msg.sender) {
            revert CanNotBuyOwnNFT();
        }
        // NFT 必须还在市场中
        //require(erc721.ownerOf(_tokenId) == address(this), "NFT not in market");
        // NFT 必须还在市场合约
        if (erc721.ownerOf(_tokenId) != address(this)) revert NFTNotInMarket();
        //require(erc20.balanceOf(msg.sender) >= price, "balance not enough");//evm会自动检查溢出问题，不需要担心，多余代码，浪费gas
        // 检查授权
        if (erc20.allowance(msg.sender, address(this)) < price) {
            revert NotApprovedEnough();
        }
        // require(
        //     erc20.allowance(msg.sender, address(this)) >= price,
        //     "not approved enough"
        // );
        //remove order先删除订单，防止重入攻击
        removeOrder(_tokenId);
        // ERC20 转账
        if (!erc20.transferFrom(msg.sender, seller, price))
            revert ERC20TransferFailed();
        //_tokenId的nft从市场合约转到买家
        erc721.safeTransferFrom(address(this), msg.sender, _tokenId);
        emit Deal(seller, msg.sender, _tokenId, price);
    }

    //取消订单
    function cancelOrder(uint256 _tokenId) external {
        address seller = orderOfId[_tokenId].seller;
        require(msg.sender == seller, "not seller");
        erc721.safeTransferFrom(address(this), seller, _tokenId); //从将nft从nft市场这个合约转回到seller的地址
        emit OrderCancelled(seller, _tokenId);
        //remove order
        removeOrder(_tokenId);
    }

    //修改nft价格
    function changPrice(uint256 _price, uint256 _tokenId) external {
        require(_price > 0, "price can not be zero");
        address seller = orderOfId[_tokenId].seller;
        require(seller == msg.sender, "only owner can do this");
        //先获取到旧的价格
        uint256 previousPrice = orderOfId[_tokenId].price;
        orderOfId[_tokenId].price = _price;
        //修改价格
        Order storage order = orderOfId[_tokenId];
        order.price = _price;
        //触发changPrice事件
        emit PriceChange(seller, _tokenId, previousPrice, _price);
    }

    //必须提供这个方法nft才能被安全的发送到nft交易市场合约,
    //当nft合约中调用transfer函数向nft交易合约转账时会触发这个函数,
    //在此函数中实现上架功能
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        //获取nft的价格并转换格式
        //uint256 price = toUint256(data, 0);
        uint256 price = abi.decode(data, (uint256));
        console.log("listting price:", price);
        require(price > 0, "price must be greater than 0");
        //上架nft到nft市场合约
        Order memory order = Order(from, tokenId, price);
        orders.push(order);
        orderOfId[tokenId] = order;
        idToOrderIndex[tokenId] = orders.length - 1;
        emit NewOrder(from, tokenId, price);
        return MAGIC_ON_ERC721_RECEIVED;
    }

    //把bytes转换成uint256
    function toUint256(
        bytes memory _bytes,
        uint256 _start
    ) public pure returns (uint256) {
        require(_start + 32 >= _start, "market:touint256_overflow");
        require(_bytes.length >= _start + 32, "market:toUint256_outOfBounds");
        uint256 temUint256;
        assembly {
            temUint256 := mload(add(add(_bytes, 0x20), _start))
        }
        return temUint256;
    }

    //删除订单
    function removeOrder(uint256 _tokenId) internal {
        uint256 index = idToOrderIndex[_tokenId];
        uint256 lastIndex = orders.length - 1;
        if (index != lastIndex) {
            //用最后最后一个元素覆盖要删除的元素
            Order memory lastOrder = orders[lastIndex];
            orders[index] = lastOrder;
            idToOrderIndex[lastOrder.tokenId] = index;
        }
        orders.pop(); //出栈，删掉最后一个元素
        delete orderOfId[_tokenId];
        delete idToOrderIndex[_tokenId];
    }

    //获取所有上架nft的数量
    function getOrderLength() external view returns (uint256) {
        return orders.length;
    }

    //所有上架的nft
    function getAllNFTs() public view returns (Order[] memory) {
        return orders;
    }

    //我的所有上架的nft
    function getMyNFTs_bak() external view returns (Order[] memory) {
        require(msg.sender != address(0), "wrong address ");
        Order[] memory myOrders = new Order[](0);
        uint256 myNFTsCount = 0;
        uint256 length = orders.length; //gas优化点：缓存storage，减少读取storage的次数
        for (uint i = 0; i < length; i++) {
            if (orders[i].seller == msg.sender) {
                //myOrders.push(orders[i]);
                Order memory order = Order(
                    orders[i].seller,
                    orders[i].tokenId,
                    orders[i].price
                );
                //myOrders[myNFTsCount]=orders[i];
                myOrders[myNFTsCount] = order;
                myNFTsCount++;
            }
        }
        return myOrders;
    }

    function getMyNFTs() external view returns (Order[] memory result) {
        require(msg.sender != address(0), "wrong address ");
        uint256 myNFTsCount = 0;
        uint256 length = orders.length; //gas优化点：缓存storage，减少读取storage的次数
        for (uint i = 0; i < length; i++) {
            if (orders[i].seller == msg.sender) {
                myNFTsCount++;
            }
        }
        result = new Order[](myNFTsCount);
        uint j = 0;
        for (uint i = 0; i < orders.length; i++) {
            if (orders[i].seller == msg.sender) {
                result[j] = orders[i];
                j++;
            }
        }
    }

    //获取我的某个上架的nft的详情
    function getMyNftDetail(
        uint256 _tokenId
    ) external view returns (Order memory) {
        require(msg.sender != address(0), "wrong address ");
        console.log("seller:", orderOfId[_tokenId].seller);
        //require(orderOfId[_tokenId].seller == msg.sender, "not your nft");
        Order memory order = orderOfId[_tokenId];
        return order;
    }

    //nft是否已上架
    function isListed(uint256 _tokenId) external view returns (bool) {
        return orderOfId[_tokenId].seller != address(0);
    }
}
