import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { Contract } from "ethers";
import { ethers } from "hardhat";

let xrc20Contract, xrc20: Contract;
let tradeContract, trade: Contract;
let owner: SignerWithAddress;
let addr1;
let addr2;

before(async function () {
  tradeContract = await ethers.getContractFactory("ExposedTrade");

  [owner, addr1, addr2] = await ethers.getSigners();

  trade = await tradeContract.deploy();

  xrc20Contract = await ethers.getContractFactory("XRC20");
  xrc20 = await xrc20Contract.deploy(trade.address, owner.address);
});

describe("Deploy Trade", function () {
  it("Deploy", async function () {
    await trade.deployed();
  });
});

describe("XRC20 Operations", function () {
  it("Simple buy-sell", async function () {
    await trade.buy(xrc20.address, {
      value: ethers.utils.parseEther("10.0"),
    });
    let ownerBalance = await xrc20.balanceOf(owner.address);
    expect(ownerBalance).not.equal(0);
    expect(await xrc20.totalSupply()).to.equal(ownerBalance);
    await trade.sell(xrc20.address, ownerBalance);
    expect(await xrc20.balanceOf(owner.address)).to.equal(0);
    expect(await xrc20.totalSupply()).to.equal(0);
  });
  it("Sell without balance", async function () {
    await expect(trade.sell(xrc20.address, 2000000)).to.be.revertedWith(
      "balance err"
    );
  });
  it("Sell without enough balance", async function () {
    await trade.buy(xrc20.address, {
      value: ethers.utils.parseEther("10.0"),
    });
    let ownerBalance = await xrc20.balanceOf(owner.address);
    await expect(
      trade.sell(xrc20.address, ownerBalance + 1)
    ).to.be.revertedWith("balance err");
  });
});

describe("Sqrt Operations", function () {
  it("Rounding", async function () {
    expect(await trade._sqrt(10)).to.equal(3);
  });
  it("Real sqrt", async function () {
    expect(await trade._sqrt(9)).to.equal(3);
  });
});
