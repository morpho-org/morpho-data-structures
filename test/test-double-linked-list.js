const { utils } = require('ethers');
const { ethers } = require('hardhat');

describe('Test DoubleLinkedList Library', () => {
  let testDoubleLinkedList;
  let addresses = [];
  let addressesLength;

  for (let i = 0; i < 700; i++) {
    addresses.push(utils.solidityKeccak256(['uint256'], [i]).slice(0, 42));
  }
  addressesLength = addresses.length;

  beforeEach(async () => {
    const TestDoubleLinkedList = await ethers.getContractFactory('TestDoubleLinkedList');
    testDoubleLinkedList = await TestDoubleLinkedList.deploy();
    await testDoubleLinkedList.deployed();
  });

  describe('Test Gas Consumption', () => {
    it('Test insert many values', async () => {
      let value = utils.parseUnits('10');
      for (let i = 0; i < addressesLength; i++) {
        const address = addresses[i];
        await testDoubleLinkedList.insertSorted(address, value);
        value = value.sub(1);
      }
    });

    it('Test remove many values (each time the first value)', async () => {
      let value = utils.parseUnits('10');
      for (let i = 0; i < addressesLength; i++) {
        const address = addresses[i];
        await testDoubleLinkedList.insertSorted(address, value);
        value = value.sub(1);
      }

      for (let i = 0; i < addressesLength; i++) {
        const address = addresses[i];
        await testDoubleLinkedList.remove(address);
      }
    });

    it('Test remove many values (each time the latest value)', async () => {
      let value = utils.parseUnits('10');
      for (let i = 0; i < addressesLength; i++) {
        const address = addresses[i];
        await testDoubleLinkedList.insertSorted(address, value);
        value = value.sub(1);
      }

      for (let i = 0; i < addressesLength; i++) {
        const address = addresses[addressesLength - i - 1];
        await testDoubleLinkedList.remove(address);
      }
    });

    it('Test length', async () => {
      let value = utils.parseUnits('10');
      for (let i = 0; i < addressesLength; i++) {
        const address = addresses[i];
        await testDoubleLinkedList.insertSorted(address, value);
        value = value.sub(1);
      }

      await testDoubleLinkedList.length();
    });

    it('Test getHead', async () => {
      let value = utils.parseUnits('10');
      for (let i = 0; i < addressesLength; i++) {
        const address = addresses[i];
        await testDoubleLinkedList.insertSorted(address, value);
        value = value.sub(1);
      }

      await testDoubleLinkedList.getHead();
    });

    it('Test getNext', async () => {
      let value = utils.parseUnits('10');
      for (let i = 0; i < addressesLength; i++) {
        const address = addresses[i];
        await testDoubleLinkedList.insertSorted(address, value);
        value = value.sub(1);
      }

      await testDoubleLinkedList.getNext(addresses[0]);
    });

    it('Test addTail', async () => {
      let value = utils.parseUnits('10');
      for (let i = 0; i < addressesLength; i++) {
        const address = addresses[i];
        await testDoubleLinkedList.addTail(address, value);
        value = value.sub(1);
      }
    });
  });
});
