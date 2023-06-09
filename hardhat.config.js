require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config({ path: ".env" });

const NEXT_PUBLIC_POLYGON_MUMBAI_RPC = process.env.NEXT_PUBLIC_POLYGON_MUMBAI_RPC
const NEXT_PUBLIC_PRIVATE_KEY = process.env.NEXT_PUBLIC_PRIVATE_KEY;
/** @type import('hardhat/config').HardhatUserConfig */

module.exports = {
  solidity: "0.8.17",
  // defaultNetwork: "matic",
  networks: {
    hardhat: {},
    polygon_mumbai: {
      url: NEXT_PUBLIC_POLYGON_MUMBAI_RPC,
      accounts: [NEXT_PUBLIC_PRIVATE_KEY],
    },
  },

};
