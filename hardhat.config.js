require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.20",
    settings: {
        optimizer: {
            enabled: true,
            runs: 200,
        },
    },
},
networks: {
    hardhat: {
        // Hardhat network configuration
    },

    'base-mainnet': {
      url: 'https://mainnet.base.org',
      accounts: [process.env.ACCT_PRIVATE_KEY],
      gasPrice: 1000000000,
      VRFCoordinator: '0xd5D517aBE5cF79B7e95eC98dB0f0277788aFF634',
      VRFKeyHash: '0xdc2f87677b01473c763cb0aee938ed3341512f6057324a584e5944e786144d70',
    },

    'base-sepolia': {
      url: 'https://sepolia.base.org',
      accounts: [process.env.ACCT_PRIVATE_KEY],
      gasPrice: 1000000000,
      VRFCoordinator: '0x5C210eF41CD1a72de73bF76eC39637bB0d3d7BEE',
      VRFKeyHash: '0x9e1344a1247c8a1785d0a4681a27152bffdb43666ae5bf7d14d24a5efd44bf71',
    },

}
};
