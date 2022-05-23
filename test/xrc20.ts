import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { Contract } from "ethers";
import { ethers } from "hardhat";

let xrc20Contract;
let xrc20: Contract;
let owner: SignerWithAddress;
let addr1: SignerWithAddress;
let addr2: SignerWithAddress;

beforeEach(async function () {
  xrc20Contract = await ethers.getContractFactory("XRC20");
  [owner, addr1, addr2] = await ethers.getSigners();
  xrc20 = await xrc20Contract.deploy(owner.address);
});

describe("Deploy XRC20", function () {
  it("Deploy", async function () {
    await xrc20.deployed();
  });
});

describe("Mint XRC20", function () {
  it("Block mint for not trade proxy", async function () {
    await expect(
      xrc20.connect(addr1).mint(owner.address, 20000)
    ).to.be.revertedWith("not trade proxy");
  });
  it("Mint for trade proxy", async function () {
    await xrc20.mint(owner.address, 20000);
  });
});
