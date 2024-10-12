// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `npx hardhat run <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

const _config_ = require("../config").config;

async function main() {
  const networkConfig = hre.network.config;

  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  const Contract = await hre.ethers.getContractFactory("FarBuyCoupon");

  const contract = await Contract.deploy(
                              (_config_.ticketPrice * 10 ** 18).toString(),
                              _config_.VRFSubscriptionId,
                              networkConfig.VRFCoordinator,
                              networkConfig.VRFKeyHash,
                          );

  await contract.waitForDeployment();

  const contractAddress = await contract.getAddress();

  console.log("Contract deployed to:", contractAddress);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});