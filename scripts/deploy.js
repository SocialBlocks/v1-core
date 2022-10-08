// scripts/create-box.js
const { ethers, upgrades } = require("hardhat");

async function main() {
  const provider = waffle.provider;

  const [owner] = await ethers.getSigners();
  
  //get owner wllet ethers balance
  let ownerBalance = await provider.getBalance(owner.address);
  console.log("Owner Balance: ", ownerBalance/ 1e18);


  // Social Blocks contracts deployment
  // const SocialBlocksToken = await ethers.getContractFactory("SocialBlocksToken");
  const SocialBlocks = await ethers.getContractFactory("SocialBlocks");

  // console.log('deploying social blocks token');
  // let socialBlocksToken = await SocialBlocksToken.deploy(); //0x512fE96aa3cC9265b94Dc3017BF0d805AF0800F2

  console.log('deploying social blocks contract...');
  let SBT = "0x076c5102c870aa5ac9d1336947dfbd5d9fbb6991"  //mumbai
  let OWNER = "0x1ca510447b07dcf686339ea6e647dc8049cdff2f" 
  let socialBlocks = await SocialBlocks.deploy(SBT, OWNER);
  
  console.log('all contracts deployed')

  // console.log("socialBlocksToken: ", socialBlocksToken.address);
  console.log("socialBlocks: ", socialBlocks.address);
  console.log("SBT: ", SBT);
  console.log("OWNER: ", OWNER);
}
(async () => {
  try {
    await main();
  } catch (error) {
    console.error(error);
    process.exit(1);
  }
})()

