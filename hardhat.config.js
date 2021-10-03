require('dotenv').config({ path: './.env.local' });
require('@nomiclabs/hardhat-etherscan');
require('@nomiclabs/hardhat-waffle');
require('hardhat-gas-reporter');
require('hardhat-deploy');

module.exports = {
  defaultNetwork: 'hardhat',
  networks: {},
  solidity: {
    version: '0.8.9',
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
  gasReporter: {
    currency: 'USD',
  },
  mocha: {
    timeout: 100000,
  },
};
