const hre = require("hardhat");

async function main() {
  const NFTMarketplace = await hre.ethers.getContractFactory("NFTMarketplace");
  const nftMarketplace = await NFTMarketplace.deploy("0xA6016Ea761eE113f448489C8CbA4741963178725");

  await nftMarketplace.deployed();

  // //TRANSFER FUNDS
  // const TransferFunds = await hre.ethers.getContractFactory("TransferFunds");
  // const transferFunds = await TransferFunds.deploy();

  // await transferFunds.deployed();

  console.log(` deployed contract Address nft ${nftMarketplace.address}`);
  // console.log(` deployed contract Address transfer ${transferFunds.address}`);

  console.log("Sleeping.....");
  // Wait for etherscan to notice that the contract has been deployed
  await sleep(40000);

  // Verify the contract after deploying
  await hre.run("verify:verify", {
    address: nftMarketplace.address,
    contract: "contracts/NFTMarketplace.sol:NFTMarketplace",
    constructorArguments: ["0xA6016Ea761eE113f448489C8CbA4741963178725"],
  });
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
