require("@nomicfoundation/hardhat-toolbox")
require("@nomiclabs/hardhat-etherscan")
require("@nomiclabs/hardhat-ethers")
require("dotenv").config()

/** @type import('hardhat/config').HardhatUserConfig */


const GOERLI_RPC_URL = process.env.GOERLI_RPC_URL
const PRIVATE_KEY = process.env.PRIVATE_KEY
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY
const POLYGONSCAN_API_KEY =process.env.POLYGONSCAN_API_KEY

module.exports = {
  solidity: "0.8.17",
  defaultNetwork: "hardhat",
  networks: {
      hardhat: {
          chainId: 31337,
          blockConfirmations: 1,
      },
      goerli: {
          chainId: 5,
          blockConfirmations: 6,
          url: GOERLI_RPC_URL,
          accounts: [PRIVATE_KEY],
      },
      hardhat: {
    },
    matic: {
      url: "https://rpc-mumbai.maticvigil.com",
      accounts: [process.env.PRIVATE_KEY],
    },
  },
  etherscan: {
      apiKey: ETHERSCAN_API_KEY,
      apiKey: POLYGONSCAN_API_KEY
  },
}
