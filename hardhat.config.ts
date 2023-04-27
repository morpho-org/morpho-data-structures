import * as dotenv from 'dotenv';
dotenv.config({ path: './.env.local' });
import '@nomiclabs/hardhat-etherscan';
import '@nomiclabs/hardhat-waffle';
import 'hardhat-gas-reporter';
import 'hardhat-contract-sizer';
import 'solidity-coverage';

module.exports = {
  defaultNetwork: 'hardhat',
  networks: {
    hardhat: {},
  },
  solidity: {
    version: '0.8.17',
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  paths: {
    sources: './test-ts',
    tests: './test-ts',
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
  gasReporter: {
    currency: 'USD',
    gasPrice: 100,
  },
  mocha: {
    timeout: 100000,
  },
};
