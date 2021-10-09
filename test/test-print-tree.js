const { utils, BigNumber } = require('ethers');
const { ethers } = require('hardhat');
const fs = require('fs');

describe('Test RedBlackBinaryTree Library', () => {
  
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

  describe('Test', () => {
    it('apply instructions', async () => {
      testRedBlackBinaryTree = await testScenario('./test/instruction.json', testRedBlackBinaryTree);
      await printTreeStucture(testRedBlackBinaryTree);
    });
  });
});


async function testScenario(testFile, tree) {
  let j = 0;
  let rawdata = fs.readFileSync(testFile);
  let steps = await JSON.parse(rawdata);
  for (j ; j < steps.length; j++) {
    step = await steps[j];
    
    if(step['action'] == 'insert'){
      tree.insert(step['address'], BigNumber.from(step['amount']));
    }
    if(step['action'] == 'delete'){
      tree.remove(step['address']);
    }
  }
  return tree;
}

async function printTreeStucture(tree) {
  let i = 0;
  let last;
  let temp;

  first = await tree.returnFirst();
  first = first.toNumber();
  next = await tree.returnNext(first);
  next = next.toNumber();

  console.log('****** Node %d ******', first);
  for (let j = 0; j < (await tree.returnGetNumberOfKeysAtValue(first)); j++) {
    console.log('At index', j, ' key: ', await tree.returnValueKeyAtIndex(first, j));
  }
  console.log('\n');

  while (next != 0) {

    temp = await tree.returnGetNumberOfKeysAtValue(next);

    console.log('****** Node %d ******', next);
    for (let j = 0; j < temp; j++) {
      console.log('At index', j, ' key: ', await tree.returnValueKeyAtIndex(next, j));
    }
    console.log('\n');

    next = await tree.returnNext(next);
    next = await next.toNumber();
  }

  return;
}
