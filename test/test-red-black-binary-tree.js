const { utils, BigNumber } = require('ethers');
const { ethers } = require('hardhat');

describe('Test RedBlackBinaryTree Library', () => {
  let testRedBlackBinaryTree;
  let addresses = [];
  let addressesLength;
  const MAX = 10 * 30;

  for (let i = 0; i < 700; i++) {
    addresses.push(utils.solidityKeccak256(['uint256'], [i]).slice(0, 42));
  }
  addressesLength = addresses.length;

  const getRandomNumber = () => Math.floor(Math.random() * MAX + 1);

  beforeEach(async () => {
    const RedBlackBinaryTree = await ethers.getContractFactory('RedBlackBinaryTree');
    const redBlackBinaryTree = await RedBlackBinaryTree.deploy();
    await redBlackBinaryTree.deployed();

    const TestRedBlackBinaryTree = await ethers.getContractFactory('TestRedBlackBinaryTree', {
      libraries: {
        RedBlackBinaryTree: redBlackBinaryTree.address,
      },
    });
    testRedBlackBinaryTree = await TestRedBlackBinaryTree.deploy();
    await testRedBlackBinaryTree.deployed();
  });

  describe('Test Gas Consumption', () => {
    it('Test insert many values', async () => {
      let value = utils.parseUnits('10');
      for (let i = 0; i < addressesLength; i++) {
        const address = addresses[i];
        await testRedBlackBinaryTree.insert(address, value);
        value = value.sub(1);
      }
    });

    it('Test remove many values (each time the first value)', async () => {
      let value = utils.parseUnits('10');
      for (let i = 0; i < addressesLength; i++) {
        const address = addresses[i];
        await testRedBlackBinaryTree.insert(address, value);
        value = value.sub(1);
      }

      for (let i = 0; i < addressesLength; i++) {
        const address = addresses[i];
        await testRedBlackBinaryTree.remove(address);
      }
    });

    it('Test remove many values (each time the latest value)', async () => {
      let value = utils.parseUnits('10');
      for (let i = 0; i < addressesLength; i++) {
        const address = addresses[i];
        await testRedBlackBinaryTree.insert(address, value);
        value = value.sub(1);
      }

      for (let i = 0; i < addressesLength; i++) {
        const address = addresses[addressesLength - i - 1];
        await testRedBlackBinaryTree.remove(address);
      }
    });

    it('Test insert and remove many random values', async () => {
      for (let i = 0; i < addressesLength; i++) {
        const address = addresses[i];
        const value = BigNumber.from(getRandomNumber());

        await testRedBlackBinaryTree.insert(address, value);
      }

      for (let i = 0; i < addressesLength; i++) {
        const address = addresses[addressesLength - i - 1];
        await testRedBlackBinaryTree.remove(address);
      }
    });

    it('Test keyExists', async () => {
      let value = utils.parseUnits('10');
      for (let i = 0; i < addressesLength; i++) {
        const address = addresses[i];
        await testRedBlackBinaryTree.insert(address, value);
        value = value.sub(1);
      }

      for (let i = 0; i < addressesLength; i++) {
        const address = addresses[i];
        await testRedBlackBinaryTree.keyExists(address);
      }
    });

    it('Test getNumberOfKeysAtValue', async () => {
      let value = utils.parseUnits('10');
      for (let i = 0; i < addressesLength; i++) {
        const address = addresses[i];
        await testRedBlackBinaryTree.insert(address, value);
        value = value.sub(1);
      }

      await testRedBlackBinaryTree.getNumberOfKeysAtValue(utils.parseUnits('10'));
    });

    it('Test last', async () => {
      let value = utils.parseUnits('10');
      for (let i = 0; i < addressesLength; i++) {
        const address = addresses[i];
        await testRedBlackBinaryTree.insert(address, value);
        value = value.sub(1);
      }

      await testRedBlackBinaryTree.last();
    });

    it('Test keyExists', async () => {
      let value = utils.parseUnits('10');
      for (let i = 0; i < addressesLength; i++) {
        const address = addresses[i];
        await testRedBlackBinaryTree.insert(address, value);
        value = value.sub(1);
      }

      await testRedBlackBinaryTree.keyExists(addresses[0]);
    });

    it('Test valueKeyAtIndex', async () => {
      let value = utils.parseUnits('10');
      for (let i = 0; i < addressesLength; i++) {
        const address = addresses[i];
        await testRedBlackBinaryTree.insert(address, value);
        value = value.sub(1);
      }

      await testRedBlackBinaryTree.valueKeyAtIndex(utils.parseUnits('10'), 0);
    });
  });
});
