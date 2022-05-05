//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";

abstract contract Token is
    ERC20 // This doesn't have to match the real contract name. Call it what you like.
{
    function mint(address to, uint256 amount) public virtual;

    function burn(address to, uint256 amount) public virtual;
}

contract Trade {
    event SellEvent(address from, uint256 amount, address tokenAddress);
    event BuyEvent(address from, uint256 amount, address tokenAddress);
    mapping(address => uint256) public currentPrices;
    address public foundation;
    bool initialized;

    uint8 public foundationPercent; // this % goes to foundation from each operation (buy/sell)

    function initialize() public {
        require(!initialized, "already initialized");
        foundation = 0x2CA62764C88F97AaF5BE02ed3f400000390C0b5d;
        foundationPercent = 2;
    }

    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    // считаем, что каждый купл. токен повышает цену на 1 ед.
    // А каждый прод. снижает на 1 ед.
    function calcXLTforTokens(address contractAddress, uint256 contractTokens)
        internal
        returns (uint256)
    {
        require(
            currentPrices[contractAddress] > 0,
            "current price <= 0. Unable to sell"
        );
        require(
            currentPrices[contractAddress] - contractTokens >= 0,
            "price bottom bound err"
        );
        uint256 resultXLT = 0;
        if (contractTokens % 2 == 1) {
            uint256 mediumPrice = currentPrices[contractAddress] -
                1 -
                (contractTokens - 1) /
                2;
            require(mediumPrice > 0, "mediumPrice <= 0");
            resultXLT = mediumPrice * contractTokens;
            currentPrices[contractAddress] =
                currentPrices[contractAddress] -
                contractTokens;
        } else {
            resultXLT = currentPrices[contractAddress] - 1;
            --currentPrices[contractAddress];
            resultXLT += calcXLTforTokens(contractAddress, contractTokens - 1);
        }
        return resultXLT;
    }

    function calcTokensForXLT(address contractAddress, uint256 xltAmount)
        internal
        returns (uint256)
    {
        require(
            xltAmount > currentPrices[contractAddress],
            "xlt wei > price token_wei"
        );
        uint256 k = 0;
        uint256 pr = currentPrices[contractAddress];
        if (currentPrices[contractAddress] == 0) {
            xltAmount -= 1;
            k = 1;
            pr = 1;
        }
        uint256 dsc = (2 * pr - 1) * (2 * pr - 1) + 8 * xltAmount;
        k += uint256(-2 * int256(pr) + 1 + int256(sqrt(dsc))) / 2;
        currentPrices[contractAddress] += k;
        return k;
    }

    function buy(address contractAddress) external payable returns (uint256) {
        require(msg.value > 0, "value <= 0");
        // calcTokensForXLT(contractAddress, msg.value);
        Token token = Token(contractAddress);
        payable(foundation).transfer((msg.value / 100) * foundationPercent);
        uint256 xltValAfterfee = msg.value -
            (msg.value / 100) *
            foundationPercent;
        uint256 totalTransferTokens = calcTokensForXLT(
            contractAddress,
            xltValAfterfee
        );

        token.mint(msg.sender, totalTransferTokens);
        emit BuyEvent(msg.sender, totalTransferTokens, contractAddress);
        return totalTransferTokens;
    }

    function sell(address contractAddress, uint256 amount)
        external
        returns (uint256)
    {
        require(amount > 0);
        Token token = Token(contractAddress);
        require(token.balanceOf(msg.sender) >= amount, "balance err");

        token.burn(msg.sender, amount);
        uint256 totalTransferXlt = calcXLTforTokens(contractAddress, amount);
        payable(foundation).transfer(
            (totalTransferXlt / 100) * foundationPercent
        );
        payable(msg.sender).transfer(
            totalTransferXlt - (totalTransferXlt / 100) * foundationPercent
        );
        emit SellEvent(
            msg.sender,
            totalTransferXlt - (totalTransferXlt / 100) * foundationPercent,
            contractAddress
        );
        return totalTransferXlt - (totalTransferXlt / 100) * foundationPercent;
    }
}
