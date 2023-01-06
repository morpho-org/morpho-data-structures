import { BigNumber, Contract } from 'ethers';
import { ethers } from 'hardhat';
import fs from 'fs';

describe('Test RedBlackBinaryTree Library', () => {
  let redBlackBinaryTree: Contract;
  let testRedBlackBinaryTree: Contract;

  beforeEach(async () => {
    const RedBlackBinaryTree = await ethers.getContractFactory('RedBlackBinaryTree');
    redBlackBinaryTree = await RedBlackBinaryTree.deploy();
    await redBlackBinaryTree.deployed();

    const RedBlackBinaryTreeMock = await ethers.getContractFactory('RedBlackBinaryTreeMock', {
      libraries: {
        RedBlackBinaryTree: redBlackBinaryTree.address,
      },
    });
    testRedBlackBinaryTree = await RedBlackBinaryTreeMock.deploy();
    await testRedBlackBinaryTree.deployed();
  });

  describe('Print tree', () => {
    it('Apply instructions', async () => {
      await testScenario('./test-ts/instruction.json', testRedBlackBinaryTree);
      await printTreeStucture(testRedBlackBinaryTree);
    });
  });
});

async function testScenario(testFile: string, tree: Contract) {
  const rawdata = fs.readFileSync(testFile);
  const steps = await JSON.parse(rawdata.toString());

  steps.map((step: any) => {
    if (step['action'] == 'insert') tree.insert(step['address'], BigNumber.from(step['amount']));
    if (step['action'] == 'delete') tree.remove(step['address']);
  });
}

async function printTreeStucture(tree: Contract) {
  const first = await tree.first();

  let data = '****** Node Value: ' + first + ' ******\n';
  const numberOfKeys = await tree.getNumberOfKeysAtValue(first);

  for (let i = 0; i < numberOfKeys; i++) {
    data += 'At index ' + i + ' key: ' + (await tree.valueKeyAtIndex(first, i)) + '\n';
  }
  data += '\n';

  let next = await tree.next(first);
  while (next != 0) {
    const numberOfKeys = await tree.getNumberOfKeysAtValue(next);

    data += '****** Node Value: ' + next + ' ******\n';
    for (let i = 0; i < numberOfKeys; i++) {
      data += 'At index ' + i + ' key: ' + (await tree.valueKeyAtIndex(next, i)).toString() + '\n';
    }
    data += '\n';

    next = await tree.next(next);
  }

  fs.writeFile('./test/output-tree-structure.txt', data, (err) => {
    if (err) throw err;
  });

  return;
}
