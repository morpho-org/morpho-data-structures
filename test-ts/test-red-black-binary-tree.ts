import { utils, BigNumber, Contract } from 'ethers';
import { ethers } from 'hardhat';
import fs from 'fs';

describe('Test RedBlackBinaryTreeOptimized Library', () => {
  let testRedBlackBinaryTreeOptimized: Contract;
  const addresses: string[] = [];
  const MAX = 10 * 30;

  for (let i = 0; i < 700; i++) {
    addresses.push(utils.solidityKeccak256(['uint256'], [i]).slice(0, 42));
  }
  const addressesLength = addresses.length;

  const getRandomNumber = () => Math.floor(Math.random() * MAX + 1);

  beforeEach(async () => {
    const RedBlackBinaryTreeOptimized = await ethers.getContractFactory('RedBlackBinaryTreeOptimized');
    const redBlackBinaryTreeOptimized = await RedBlackBinaryTreeOptimized.deploy();
    await redBlackBinaryTreeOptimized.deployed();

    const RedBlackBinaryTreeOptimizedMock = await ethers.getContractFactory('RedBlackBinaryTreeOptimizedMock', {
      libraries: {
        RedBlackBinaryTreeOptimized: redBlackBinaryTreeOptimized.address,
      },
    });
    testRedBlackBinaryTreeOptimized = await RedBlackBinaryTreeOptimizedMock.deploy();
    await testRedBlackBinaryTreeOptimized.deployed();
  });

  describe('Test Gas Consumption', () => {
    it('test first', async () => {
      await testRedBlackBinaryTreeOptimized.insert('0xDaB8C61fae3A170CF2f4411D4689BD62Fa733021', 1);
      await testRedBlackBinaryTreeOptimized.insert('0x37611DA9a94cf3b466b8f1bEae206A26A3A6E4fC', 2);
      await testRedBlackBinaryTreeOptimized.insert('0xD2b7Cfa9A7662eFD8450b034FdD472Ffd8f36D68', 3);
      await testRedBlackBinaryTreeOptimized.insert('0x907b0FD3408915DDf4a1915e6D57d683c81b2E27', 4);
      await testRedBlackBinaryTreeOptimized.insert('0xa626Aef7c0dD74c825b786166b00929388c568e9', 5);
      printTreeStucture(testRedBlackBinaryTreeOptimized);
    });

    it('Test insert many values', async () => {
      let value = utils.parseUnits('10');
      for (let i = 0; i < addressesLength; i++) {
        const address = addresses[i];
        await testRedBlackBinaryTreeOptimized.insert(address, value);
        value = value.sub(1);
      }
    });

    it('Test remove many values (each time the first value)', async () => {
      let value = utils.parseUnits('10');
      for (let i = 0; i < addressesLength; i++) {
        const address = addresses[i];
        await testRedBlackBinaryTreeOptimized.insert(address, value);
        value = value.sub(1);
      }

      for (let i = 0; i < addressesLength; i++) {
        const address = addresses[i];
        await testRedBlackBinaryTreeOptimized.remove(address);
      }
    });

    it('Test remove many values (each time the latest value)', async () => {
      let value = utils.parseUnits('10');
      for (let i = 0; i < addressesLength; i++) {
        const address = addresses[i];
        await testRedBlackBinaryTreeOptimized.insert(address, value);
        value = value.sub(1);
      }

      for (let i = 0; i < addressesLength; i++) {
        const address = addresses[addressesLength - i - 1];
        await testRedBlackBinaryTreeOptimized.remove(address);
      }
    });

    xit('Test insert and remove many random values', async () => {
      for (let i = 0; i < addressesLength; i++) {
        const address = addresses[i];
        const value = BigNumber.from(getRandomNumber());

        await testRedBlackBinaryTreeOptimized.insert(address, value);
      }

      for (let i = 0; i < addressesLength; i++) {
        const address = addresses[addressesLength - i - 1];
        await testRedBlackBinaryTreeOptimized.remove(address);
      }
    });

    it('Test keyExists', async () => {
      let value = utils.parseUnits('10');
      for (let i = 0; i < addressesLength; i++) {
        const address = addresses[i];
        await testRedBlackBinaryTreeOptimized.insert(address, value);
        value = value.sub(1);
      }

      for (let i = 0; i < addressesLength; i++) {
        const address = addresses[i];
        await testRedBlackBinaryTreeOptimized.keyExists(address);
      }
    });

    it('Test last', async () => {
      let value = utils.parseUnits('10');
      for (let i = 0; i < addressesLength; i++) {
        const address = addresses[i];
        await testRedBlackBinaryTreeOptimized.insert(address, value);
        value = value.sub(1);
      }

      await testRedBlackBinaryTreeOptimized.last();
    });
  });
});

async function printTreeStucture(tree: Contract) {
  let data = '';

  const first = await tree.first();
  let next = await tree.next(first);

  data += 'key: ' + first + ' value: ' + (await tree.returnKeyToValue(first)) + '\n';
  data += '\n';

  while (next != '0x0000000000000000000000000000000000000000') {
    data += 'key: ' + next + ' value: ' + (await tree.returnKeyToValue(next)) + '\n';
    data += '\n';
    next = await tree.next(next);
  }

  fs.writeFile('./test/output-tree-structure.txt', data, (err) => {
    if (err) throw err;
  });

  return;
}
