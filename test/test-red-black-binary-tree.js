const { utils } = require('ethers');
const { ethers } = require('hardhat');

describe('Test RedBlackBinaryTree Library', () => {
  let testRedBlackBinaryTree;
  let addresses = [];
  let addressesLength;

  for (let i = 0; i < 700; i++) {
    addresses.push(utils.solidityKeccak256(['uint256'], [i]).slice(0, 42));
  }
  addressesLength = addresses.length;

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

    it('Test getNodeCount', async () => {
      let value = utils.parseUnits('10');
      for (let i = 0; i < addressesLength; i++) {
        const address = addresses[i];
        await testRedBlackBinaryTree.insert(address, value);
        value = value.sub(1);
      }

      await testRedBlackBinaryTree.getNodeCount(utils.parseUnits('10'));
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
