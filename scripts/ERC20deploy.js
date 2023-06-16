const hre = require("hardhat");

async function main() {
  const NFTToken = await hre.ethers.getContractFactory("NFTMarketToken");
  const nftToken = await NFTToken.deploy("NFT Market Token", "NFTT");

  await nftToken.deployed();

  // //TRANSFER FUNDS
//   const TransferFunds = await hre.ethers.getContractFactory("TransferFunds");
//   const transferFunds = await TransferFunds.deploy();

//   await transferFunds.deployed();

  console.log(` deployed contract Address nft ${nftToken.address}`);
//   console.log(` deployed contract Address transfer ${transferFunds.address}`);

  console.log("Sleeping.....");
  // Wait for etherscan to notice that the contract has been deployed
  await sleep(40000);

  // Verify the contract after deploying
  await hre.run("verify:verify", {
    address: nftToken.address,
    contract: "contracts/NFTMarketToken.sol:NFTMarketToken",
    constructorArguments: ["NFT Market Token", "NFTT"],
  }); 
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
