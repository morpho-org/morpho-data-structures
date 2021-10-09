const { utils, BigNumber } = require('ethers');
const { ethers } = require('hardhat');
const fs = require('fs');

describe('Test RedBlackBinaryTree Library', () => {
<<<<<<< HEAD
=======
  
>>>>>>> 01d811e (feat: read instructions from JSON file)
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

<<<<<<< HEAD
=======

>>>>>>> 01d811e (feat: read instructions from JSON file)
async function testScenario(testFile, tree) {
  let j = 0;
  let rawdata = fs.readFileSync(testFile);
  let steps = await JSON.parse(rawdata);
<<<<<<< HEAD
  for (j; j < steps.length; j++) {
    step = await steps[j];

    if (step['action'] == 'insert') {
      tree.insert(step['address'], BigNumber.from(step['amount']));
    }
    if (step['action'] == 'delete') {
=======
  for (j ; j < steps.length; j++) {
    step = await steps[j];
    
    if(step['action'] == 'insert'){
      tree.insert(step['address'], BigNumber.from(step['amount']));
    }
    if(step['action'] == 'delete'){
>>>>>>> 01d811e (feat: read instructions from JSON file)
      tree.remove(step['address']);
    }
  }
  return tree;
}

async function printTreeStucture(tree) {
  let i = 0;
  let temp;

  let data = '';

  first = await tree.returnFirst();
  first = first.toNumber();
  next = await tree.returnNext(first);
  next = next.toNumber();

  data += '****** Node ' + (await first.toString()) + ' ****** \n';
  for (let j = 0; j < (await tree.returnGetNumberOfKeysAtValue(first)); j++) {
    data += 'At index' + (await j.toString()) + ' key: ' + (await (await tree.returnValueKeyAtIndex(first, j)).toString()) + '\n';
  }
  data += '\n';

  while (next != 0) {
    temp = await tree.returnGetNumberOfKeysAtValue(next);

    data += '****** Node ' + (await next.toString()) + ' ****** \n';
    for (let j = 0; j < temp; j++) {
      data += 'At index ' + (await j.toString()) + ' key: ' + (await (await tree.returnValueKeyAtIndex(next, j)).toString()) + '\n';
    }
    data += '\n';

    next = await tree.returnNext(next);
    next = await next.toNumber();
  }
  fs.writeFile('./test/Output_Tree_Structure.txt', data, (err) => {
    if (err) throw err;
  });

  return;
}
