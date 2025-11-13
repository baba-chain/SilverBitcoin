require("@nomiclabs/hardhat-ethers");
require("dotenv").config();

module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.8.17",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          },
        },
      }
    ],
  },

  defaultNetwork: "hardhat",
  networks: {
    hardhat: {},

    // SilverBitcoin Production Mainnet
    silverbitcoin: {
      url: "https://mainnet-rpc.silverbitcoin.org/",
      chainId: 5200,
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      gasPrice: "auto",
      timeout: 60000,
      gas: "auto",
      gasMultiplier: 1.2,
    },

    // SilverBitcoin Test Server
    silverbitcoin_test: {
      url: process.env.RPC_URL || "http://34.122.141.167:8546",
      chainId: 5200,
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      gasP

    // Local development network (if running locally)
    local: {
      url: "http://localhost:8546",
      chainId: 5200,
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      gasPrice: "auto",
      gas: "auto",
      gasMultiplier: 1.2,
    }
  },

  // Global gas settings
  gasReporter: {
    enabled: true,
    currency: 'USD',
  },

  // Mocha timeout for tests
  mocha: {
    timeout: 60000
  }
};
