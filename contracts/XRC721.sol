//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

struct MarketItem {
    bool isValue;
    uint256 price;
}

contract XLTONENFT is ERC721URIStorage, Ownable {
    uint256 public mintPrice = 10 ether;
    uint256 public minListPrice = 30 ether;
    address public admin;
    using Counters for Counters.Counter;
    address public foundation = 0xC7c8F21e30d6F8d5319FFeD8D6757FEEA87e9155;
    Counters.Counter private _tokenIds;
    mapping(uint256 => MarketItem) public tokensForSale;
    mapping(uint256 => address) public creators;

    modifier onlyAdmin() {
        require(admin == msg.sender, "not admin");
        _;
    }

    constructor() public ERC721("XLTONECLCT", "XLTNFT") {
        admin = msg.sender;
    }

    function setAdmin(address _admin) external onlyAdmin {
        admin == _admin;
    }

    function updateConf(
        uint256 _mintPrice,
        uint256 _minListPrice,
        address _foundation
    ) external onlyAdmin {
        mintPrice = _mintPrice;
        minListPrice = _minListPrice;
        foundation = _foundation;
    }

    function mintNFT(address recipient, string memory tokenURI)
        public
        payable
        returns (uint256)
    {
        require(msg.value >= 10 ether, "mint price is 10 XLT");
        payable(foundation).transfer(msg.value);
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(recipient, newItemId);

        _setTokenURI(newItemId, tokenURI);
        creators[newItemId] = recipient;
        return newItemId;
    }

    function isValidToken(uint256 _tokenId) internal view returns (bool) {
        return _tokenId != 0 && _tokenId <= _tokenIds.current();
    }

    function setForSale(uint256 _tokenId, uint256 price) external {
        address owner = ownerOf(_tokenId);

        require(price >= minListPrice, "price < min list price");
        require(isValidToken(_tokenId));
        require(owner == msg.sender);

        require(!tokensForSale[_tokenId].isValue);

        // allowance[_tokenId] = address(this);
        tokensForSale[_tokenId] = MarketItem(true, price);
        // set the sale price etc
        approve(address(this), _tokenId);
        // emit Approval(owner, address(this), _tokenId);
    }

    function buy(uint256 _tokenId) external payable {
        address buyer = msg.sender;

        require(isValidToken(_tokenId), "incorrect token id");
        require(
            getApproved(_tokenId) == address(this),
            "contract is not approved"
        );
        require(tokensForSale[_tokenId].isValue, "not for sale");
        require(_tokenId > 0, "tokenId must not be zero");
        require(msg.value >= tokensForSale[_tokenId].price, "incorrect price");

        // remove token from tokensForSale
        delete tokensForSale[_tokenId];

        // pay the seller
        payable(creators[_tokenId]).transfer(msg.value / 10);
        payable(ownerOf(_tokenId)).transfer(
            msg.value - msg.value / 20 - msg.value / 10
        );
        payable(foundation).transfer(msg.value / 20);
        _transfer(ownerOf(_tokenId), buyer, _tokenId);
    }
}
