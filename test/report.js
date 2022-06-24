const { expect } = require("chai");
const { ethers } = require("hardhat");

describe('btfs status test', function () {
  const DefaultMakerOrderHash = "0x88da00e25f50cd90beb85bda16dba18a3d02de76d850d1f9c78fb834687ebc19";

  let owner, user;
  beforeEach(async function () {

    [owner, user] = await ethers.getSigners();
    console.log(">>> owner, user:", owner.address, user.address);

    this.Greeter = await ethers.getContractFactory("BtfsStatusTest");
    this.greeter = await this.Greeter.deploy();

  });

  describe('--- hash', function () {
    it("Should calculate MakerOrderHash correctly", async function () {


      // 这个 order 的数据是 looksRare 测试网的一个真实数据（除了v/r/s）
      let MakerBidOrder = {
        signer: "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
        bttcAddr: "0x4a5077AE6850ced1642551a88856834AaA20E900",
        amount: 1,
        // 不参与 hash 计算
        v: 28,
        r: "0x0304d9e6a2721c019e3def812ff283d9bf723616dd24353af22f937dc1d033fe",
        s: "0x508367ae23b8b300de331b9a63a2113498f827fce7a5434544da210ddb677285"
      };
      let hash = await this.greeter.testHash(MakerBidOrder);
      console.log("... hash = ", hash)
      // expect(hash).to.equal(DefaultMakerOrderHash);
    });
  })

  describe('--- sign', function () {
    it("Should calculate signature correctly", async function() {
      let signature = await user.signMessage(DefaultMakerOrderHash);
      let signparts = ethers.utils.splitSignature(signature);
      console.log("... signparts = ", signparts)
      // expect(signparts.v).to.equal(28);
      // expect(signparts.r).to.equal("0xf27009f3dbcb43ed7da71ca6283ee6847a110622c966823543dfb084aa79969b");
      // expect(signparts.s).to.equal("0x73da4d70fd6f3f9d070030ce4baadbb7f9479737d58c9da1c4774c71290bfab1");

      let MakerBidOrder = {
        signer: "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
        bttcAddr: "0x4a5077AE6850ced1642551a88856834AaA20E900",
        amount: 1,
        // 不参与 hash 计算
        v: signparts.v,
        r: signparts.r,
        s: signparts.s
      };

      console.log("... MakerBidOrder = ", MakerBidOrder);

      console.log("");
      console.log("");
      console.log("... begin validateOrder");
      await this.greeter.validateOrder(MakerBidOrder)
    });
  })
});
