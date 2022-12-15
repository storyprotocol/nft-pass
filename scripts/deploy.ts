import { ethers } from "hardhat";

async function main() {

  const [deployer] = await ethers.getSigners();

  console.log(
      "Deploying contracts with the account:",
      deployer.address
  );
  console.log("Account balance:", (await deployer.getBalance()).toString());
  const StoryPass = await ethers.getContractFactory("StoryPass");
  const storyPass = await StoryPass.deploy();
  await storyPass.deployed();

  console.log("StoryPass deployed to:", storyPass.address);

  const TestBAYC = await ethers.getContractFactory("TestBAYC");
  const testBAYC = await TestBAYC.deploy();
  await testBAYC.deployed();

  console.log("TestBAYC deployed to:", testBAYC.address);

  const ChainlinkDataSource = await ethers.getContractFactory("ChainlinkDataSource");
  const chainlinkDataSource = await ChainlinkDataSource.deploy();
  await chainlinkDataSource.deployed();
  console.log("ChainlinkDataSource deployed to:", chainlinkDataSource.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
