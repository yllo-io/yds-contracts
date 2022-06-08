//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

abstract contract Token is ERC20 {
    function mint(address to, uint256 amount) public virtual;

    function burn(address to, uint256 amount) public virtual;
}

abstract contract Trade {
    event SellEvent(address from, uint256 amount, address tokenAddress);
    event BuyEvent(address from, uint256 amount, address tokenAddress);
    mapping(address => uint256) public currentPrices;

    function buy(address contractAddress)
        external
        payable
        virtual
        returns (uint256);

    function sell(address contractAddress, uint256 amount)
        external
        virtual
        returns (uint256);
}

contract FlashTrade {
    uint256 public xltBound = 0.1 ether;
    address public pjAddress;
    address public xrc20Address;
    address public owner;

    address public tradeContractProxyAddress;

    //  = 0x916Bb4C1960Abb890CC053d00e685f21EA30fC58;

    constructor(
        address _pjAddress,
        address _xrc20Address,
        address _tradeContractProxyAddress
    ) {
        tradeContractProxyAddress = _tradeContractProxyAddress;
        owner = msg.sender;
        pjAddress = _pjAddress;
        xrc20Address = _xrc20Address;
    }

    function buy(uint256 xltAmount, address buyerAddress) external {
        require(xltAmount > xltBound, "xlt amount is too small");
        Trade trade = Trade(tradeContractProxyAddress);
        uint256 boughtXRC20 = trade.buy{value: xltAmount - xltBound}(
            xrc20Address
        );
        Token xrc20 = Token(xrc20Address);
        xrc20.transfer(buyerAddress, boughtXRC20);
        payable(buyerAddress).transfer(xltBound);
    }

    function withdraw() external {
        require(msg.sender == owner || msg.sender == pjAddress);
        payable(msg.sender).transfer(address(this).balance);
    }

    event Received(address, uint256);

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}
