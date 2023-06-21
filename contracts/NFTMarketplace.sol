// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract NFTMarketplace is ERC721URIStorage, ReentrancyGuard, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private _tokenIds;
    Counters.Counter private _itemsSold;
    address payable contractOwner;
    ERC20 public nftToken;
    uint256 public listingPrice = 0.025 ether;
    uint256 public duration = 5 minutes;
    uint256 public royaltyPercentage = 2;
    uint256 public rewardsForListing = 1 * 10 ** 18;

    struct MarketItem {
        uint256 tokenId;
        address payable originalCreator;
        address payable previousOwner;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
        uint256 highestBid;
        address highestBidder;
        uint256 startAuctionTime;
    }

    mapping(uint256 => MarketItem) public idToMarketItem;

    event MarketItemCreated(
        uint256 indexed tokenId,
        address indexed seller,
        address indexed owner,
        uint256 price,
        bool sold,
        uint256 highestBid,
        address highestBidder,
        uint256 startAuctionTime
    );

    event BidPlaced(
        uint256 indexed tokenId,
        address indexed bidder,
        uint256 value
    );


    constructor(address _nftToken)
        ERC721("NFT Market Token", "NFTT")
    {
        contractOwner = payable(msg.sender);
        nftToken = ERC20(_nftToken);
    }

    /* Updates the listing price of the contract */
    function updateListingPrice(uint256 _listingPrice)
        public
        onlyOwner
    {
        listingPrice = _listingPrice;
    }

    /* Updates the royalty percentage of the contract */
    function updateRoyaltyPercentage(uint256 _royaltyPercentage)
        public
        onlyOwner
    {
        royaltyPercentage = _royaltyPercentage;
    }

    /* Updates the reward for listing an nft*/
    function updateRewardsForListing(uint256 _rewardsForListing)
        public
        onlyOwner
    {
        rewardsForListing = _rewardsForListing;
    }

    /* Mints a token and lists it in the marketplace */
    function createToken(string memory tokenURI, uint256 startPrice)
        public
        payable
        nonReentrant
        returns (uint256)
    {
        require(msg.value == listingPrice, "Price must be same as listing price");

        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);

        MarketItem memory item = MarketItem(
            newTokenId,
            payable(msg.sender), // originalCreator
            payable(address(0)), // previousOwner, set to 0 initially
            payable(msg.sender), // seller
            payable(address(this)), // owner
            startPrice,
            false,
            0,
            address(0),
            block.timestamp
        );
        idToMarketItem[newTokenId] = item;

        // Transfer the NFT to the Contract address for sale
        _transfer(msg.sender, address(this), newTokenId);

        nftToken.transfer(msg.sender, rewardsForListing);

        emit MarketItemCreated(
            newTokenId,
            msg.sender,
            address(this),
            startPrice,
            false,
            0,
            address(0),
            block.timestamp
        );

        return newTokenId;
    }

    /* Creates the sale of a marketplace item */
    /* Transfers ownership of the item, as well as funds between parties */
    function createMarketSale(uint256 tokenId)
        public
        payable
        nonReentrant
    {
        MarketItem storage item = idToMarketItem[tokenId];

        require(
            block.timestamp >= item.startAuctionTime + duration,
            "Auction time is not over yet"
        );
        require(
            msg.sender == item.highestBidder,
            "Only the highest bidder can buy the token"
        );

        item.sold = true;
        item.previousOwner = item.seller; // update previous owner
        item.owner = payable(msg.sender);
        item.seller = payable(address(0)); // item is not for sale anymore

        _transfer(address(this), msg.sender, tokenId);

        uint256 royaltyAmount = item.highestBid.mul(royaltyPercentage).div(100);
        item.originalCreator.transfer(royaltyAmount); // transfer royalties to the original creator of the NFT

        payable(contractOwner).transfer(listingPrice);
        payable(item.previousOwner).transfer(item.highestBid.sub(royaltyAmount)); // pay the previous owner
    }

    function placeBid(uint256 tokenId)
        public
        payable
        nonReentrant
    {
        MarketItem storage item = idToMarketItem[tokenId];

        require(
            block.timestamp <= item.startAuctionTime + duration,
            "The auction time is over"
        );
        require(
            msg.value > item.highestBid,
            "There already is a higher or equal bid"
        );

        // Refund the old highest bidder
        if (item.highestBid > 0) {
            payable(item.highestBidder).transfer(item.highestBid);
        }

        item.highestBid = msg.value;
        item.highestBidder = msg.sender;

        emit BidPlaced(tokenId, msg.sender, msg.value);
    }

    /* Returns all unsold market items */
    function fetchMarketItems() public view returns (MarketItem[] memory) {
        uint256 itemCount = _tokenIds.current();
        uint256 unsoldItemCount = _tokenIds.current() - _itemsSold.current();
        uint256 currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](unsoldItemCount);
        for (uint256 i = 0; i < itemCount; i++) {
            if (idToMarketItem[i + 1].owner == address(this)) {
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    /* Returns only items that a user has purchased */
    function fetchMyNFTs() public view returns (MarketItem[] memory) {
        uint256 totalItemCount = _tokenIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].owner == msg.sender) {
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].owner == msg.sender) {
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    /* Returns only items a user has listed */
    function fetchItemsListed() public view returns (MarketItem[] memory) {
        uint256 totalItemCount = _tokenIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].seller == msg.sender) {
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].seller == msg.sender) {
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function getListingPrice() public view returns (uint256) {
        return listingPrice;
    }

}