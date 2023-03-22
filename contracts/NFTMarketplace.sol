//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "hardhat/console.sol";

contract NFTMarketplace is ERC721URIStorage {

    address payable owner;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    Counters.Counter private _itemsSold;

    uint256 listPrice = 0.00001 ether;

    constructor() ERC721("CyberMonkey Metaverse", "MFT") {
        owner = payable(msg.sender);
    }

    struct ListedToken {
        uint256 tokenId;
        address payable owner;
        address payable seller;
        uint256 price;
        bool sold;
    }

    event idListedItemCreated(
        uint256 tokenId,
        address owner,
        address seller,
        uint256 price,
        bool sold
    );

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner can call this function");
        _;
    }

    mapping(uint256 => ListedToken) private idToListedToken;

    function updateListPrice(uint256 _listPrice) public payable onlyOwner {
        listPrice = _listPrice;
    }

    function getListPrice() public view returns (uint256) {
        return listPrice;
    }

    function getLatestIdToListedToken() public view returns (ListedToken memory) {
        uint256 currentTokenId = _tokenIds.current();
        return idToListedToken[currentTokenId];
    }

    function getListedForTokenId(uint256 tokenId) public view returns (ListedToken memory) {
        return idToListedToken[tokenId];
    }

    function getCurrentToken() public view returns (uint256) {
        return _tokenIds.current();
    }  

    function createToken(string memory tokenURI, uint256 price) public payable returns (uint) {
        require(msg.value == listPrice, "send enough ether to list");
        require(price > 0, "Make sure the price isn't negative");

        _tokenIds.increment();
        uint256 currentTokenId = _tokenIds.current();
        _mint(msg.sender, currentTokenId);

        _setTokenURI(currentTokenId, tokenURI);

        createListedToken(currentTokenId, price);

        return currentTokenId;
    }

    function createListedToken(uint256 tokenId, uint256 price) private {
        idToListedToken[tokenId] = ListedToken(
            tokenId,
            payable(address(this)),
            payable(msg.sender),
            price,
            false
        );

        _transfer(msg.sender, address(this), tokenId);

        emit idListedItemCreated(
            tokenId,
            address(this),
            msg.sender,
            price,
            false 
        );
    }

    function reSellToken(uint256 tokenId, uint256 price) public payable {
        require(idToListedToken[tokenId].owner == msg.sender, "only owner can perform the sell of the token");

        require(msg.value == listPrice, "price must be equal to the listing price");

        idToListedToken[tokenId].sold = false;
        idToListedToken[tokenId].price = price;
        idToListedToken[tokenId].seller = payable(msg.sender);
        idToListedToken[tokenId].owner = payable(address(this));

        _itemsSold.decrement();

        _transfer(msg.sender, address(this), tokenId);
    }

    function createListedToken(uint256 tokenId) public payable {
        uint price = idToListedToken[tokenId].price;

        require(
            msg.value == price,
            "Please submit the asking price in order to complete the purchase"
        );

        idToListedToken[tokenId].owner = payable(msg.sender);
        idToListedToken[tokenId].sold = true;
        idToListedToken[tokenId].owner = payable(address(0));

        _itemsSold.increment();

        _transfer(address(this), msg.sender, tokenId);

        payable(owner).transfer(listPrice);
        payable(idToListedToken[tokenId].seller).transfer(msg.value);

    }

    function getUnSoldNFTs() public view returns (ListedToken[] memory) {
        uint nftCount = _tokenIds.current();
        uint unSoldTokens = _tokenIds.current() - _itemsSold.current();
        ListedToken[] memory tokens = new ListedToken[] (unSoldTokens);

        uint currentIndex = 0;

        for(uint i=0;i<nftCount;i++) 
        {
            if(idToListedToken[i + 1].owner == address(this)) {

            }
            uint currentId = i + 1;
            ListedToken storage currentItem = idToListedToken[currentId];
            tokens[currentIndex] = currentItem;
            currentIndex += 1;
        }

        return tokens;
    }

    function getListedNFTs() public view returns (ListedToken[] memory) {
        uint nftCount = _tokenIds.current();

        uint currentIndex = 0;
        uint itemCount = 0;

        for(uint i = 0; i < nftCount; i ++) {
            if(idToListedToken[i+1].seller == msg.sender) {
                itemCount += 1;
            }
        }

        ListedToken[] memory tokens = new ListedToken[] (itemCount);

        for(uint i=0;i<nftCount;i++) 
        {
            if(idToListedToken[i + 1].seller == msg.sender) {

            }
            uint currentId = i + 1;
            ListedToken storage currentItem = idToListedToken[currentId];
            tokens[currentIndex] = currentItem;
            currentIndex += 1;
        }

        return tokens;
    }

    function getMyNFTs() public view returns(ListedToken[] memory) {
        uint totalItemCount = _tokenIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;


        for(uint i=0; i < totalItemCount; i++) 
        {
            if(idToListedToken[i+1].owner == msg.sender) {
                itemCount += 1;
            } 
        }


        ListedToken[] memory items = new ListedToken[] (itemCount);
        for(uint i=0; i < totalItemCount; i++) {
            if(idToListedToken[i+1].owner == msg.sender) {
                uint currentId = i+1;
                ListedToken storage currentItem = idToListedToken[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;        
    }

}