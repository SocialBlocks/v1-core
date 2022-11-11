// scripts/create-box.js
const { ethers, upgrades } = require("hardhat");
const {abi:socialBlocksTokenABI} = require("../artifacts/contracts/SocialBlocksToken.sol/SocialBlocksToken.json");

async function main() {
  try {
    

  const provider = waffle.provider;

  const [owner] = await ethers.getSigners();
  
  //get owner wllet ethers balance
  let ownerBalance = await provider.getBalance(owner.address);
  console.log("Owner Balance: ", ownerBalance/ 1e18);


  // Social Blocks contracts deployment
  const SocialBlocks = await ethers.getContractFactory("SocialBlocks");
  // const SocialBlocksToken = await ethers.getContractFactory('SocialBlocksToken');



  let socialBlocksToken;
  // console.log('deploying social blocks token...');
  // socialBlocksToken = await SocialBlocksToken.deploy();
  // await socialBlocksToken.deployed();
  socialBlocksToken = await ethers.getContractAt(socialBlocksTokenABI, "0xa030a24efb9348632dd17ea11294805bed482d6c", owner); //aurora testnet
  console.log(socialBlocksToken.address)

  console.log('deploying social blocks contract...');
  let SBT = "0x076c5102c870aa5ac9d1336947dfbd5d9fbb6991"  //mumbai
  let OWNER = "0x1ca510447b07dcf686339ea6e647dc8049cdff2f" 
  let socialBlocks = await SocialBlocks.deploy(socialBlocksToken.address ? socialBlocksToken.address : SBT, OWNER);
  // // await socialBlocks.deployed();
  
  // //make main contract owner of token contract for minitng and burning of SBT
  await socialBlocksToken.connect(owner).addAdmin(socialBlocks.address);  
  console.log('all contracts deployed')

  console.log("socialBlocks: ", socialBlocks.address);
  console.log("SBT: ", socialBlocksToken ? socialBlocksToken.address : SBT);
  console.log("OWNER: ", OWNER);
  } catch (error) {
    console.log(error);
  }
}
(async () => {
  try {
    await main();
  } catch (error) {
    console.error(error);
    process.exit(1);
  }
})()

