import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { BigNumber, Contract } from "ethers";
import { ethers, waffle } from "hardhat";

let xrc20Contract, xrc20: Contract;
let tradeContract, trade: Contract;
let flashTradeContract, flashTrade: Contract;

let owner: SignerWithAddress;
let addr1: SignerWithAddress;
let addr2: SignerWithAddress;

before(async function () {
  tradeContract = await ethers.getContractFactory("ExposedTrade");
  [owner, addr1, addr2] = await ethers.getSigners();
  trade = await tradeContract.deploy();

  xrc20Contract = await ethers.getContractFactory("XRC20");
  xrc20 = await xrc20Contract.deploy(trade.address, owner.address);

  flashTradeContract = await ethers.getContractFactory("FlashTrade");
  flashTrade = await flashTradeContract.deploy(
    addr1.address,
    xrc20.address,
    trade.address
  );
});

describe("Deploy FlashTrade", function () {
  it("Deploy", async function () {
    await flashTrade.deployed();
  });
});

describe("Operations", function () {
  it("Buy for all", async function () {
    await owner.sendTransaction({
      to: flashTrade.address,
      value: ethers.utils.parseEther("10.0"),
    });

    await flashTrade.buy(ethers.utils.parseEther("10.0"), addr2.address);
    expect(await waffle.provider.getBalance(flashTrade.address)).to.equal(0);

    expect(await xrc20.balanceOf(addr2.address)).not.equal(0);
  });
  it("Withdraw", async function () {
    await owner.sendTransaction({
      to: flashTrade.address,
      value: ethers.utils.parseEther("10.0"),
    });
    expect(await waffle.provider.getBalance(flashTrade.address)).to.equal(ethers.utils.parseEther("10.0"));

    await flashTrade.withdraw();
    expect(await waffle.provider.getBalance(flashTrade.address)).to.equal(0);
    expect(await waffle.provider.getBalance(owner.address)).not.equal(0);
  });
});
