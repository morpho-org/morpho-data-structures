# Morpho Data Structures 🦋

This repository contains the data structures that are used in Morpho's matching engine.
The data structures are built to be secure and gas efficient.

## Double Linked List

The current implementation of the double-linked list is based on this [article](https://hackernoon.com/a-linked-list-implementation-for-ethereum-deep-dive-oy9432pa) written by Alberto Cuesta Cañada. You can find the repository [here](https://github.com/HQ20/contracts/tree/master/contracts/lists). Note that the code has been modified to meet our own needs and to allow us to sort the first accounts of the double-linked list. Our implementation is not a generalized one.
What you can do with it:

- Insert an address sorted by a value passed along this address.
- Insert (and its value) before an account.

## Red Black Binary Tree

A [Red Black Binary Tree](https://en.wikipedia.org/wiki/Red%E2%80%93black_tree) is a kind of binary tree that allows insertion/deletion/search in `O(log(n))`.
Our implementation is a modified version of the [OrderStatisticsTree repository](https://github.com/rob-Hitchens/OrderStatisticsTree) written by [Rob Hitechn](https://github.com/rob-Hitchens) which is also based on [BokkyPooBahsRedBlackTreeLibrary repository](https://github.com/bokkypoobah/BokkyPooBahsRedBlackTreeLibrary) written by [bokkypoobah](https://github.com/bokkypoobah).
Our modified version makes keys unique items instead of just (key, value) unique pairs.

In order to manipulate a binary tree and visualize how it manages to stay balanced, this [tool](https://www.cs.usfca.edu/~galles/visualization/RedBlack.html) is very useful. You can also find [here](http://ion.uwinnipeg.ca/~ychen2/advancedAD/Red-black%20Tree.pdf) the pseudo-code logic of the tree's function.

## Heap based ordering

This implementation is based on a heap data structure and refines it by adding an unsorted portion after it. This gives us an approximation of a heap, and thus operations are performed in constant time.

At least the first `maxSortedUsers / 2` addresses are sorted in the Heap. To keep constant time operation, we divide by two the size of the Heap once the size overtakes the `maxSortedUsers` number. It means that we remove all leaves of the heap.

The choice of this implementation is explained by the desire to store a maximum of high-value nodes in the heap to use them for peer-to-peer matching.
Indeed, a naive implementation that would remove the tail and insert new values at `maxSortedUsers` (once the heap is full), would end up concentrating all new values on the same single path from the leaf to the root node because the `shiftUp` function will be always called from the same node. The risk is that low-value nodes stay in the Heap and that all the liquidity will be concentrated on the path from the leaf of index 'maxSortedUsers' to the root.
Removing all the leaves enables the protocol to remove low-value nodes and to call the `shiftUp` function at different locations in the Heap. This process is meant to keep a maximum of liquidity available in the heap for peer-to-peer lending.
The main entry point is the `update` function, calling internally either `insert`, `increase`, `decrease` or `remove`.

## Other data structures

Other data structures may be explored in the future and we are open to any suggestions or optimization of current implementations ⚡️

# Contributing

In this section, you will find some guidelines to read before contributing to the project.

## Setup

Update git submodules:

```
git submodule update --init --recursive
```

Run yarn:

```
yarn
```

## Testing

The tests can be run with [Foundry](https://github.com/foundry-rs/foundry).

For the `RedBlackBinaryTree`, you can run the tests with hardhat with `yarn test`.

## Creating issues and PRs

For issues and PR, please use conventional naming and add Morpho's contributors to review your code or tackle your issue.

## Before merging a PR

Before merging a PR:

- PR must have been reviewed by reviewers. They must deliver a complete report on the smart contracts (see the section below).
- Comments and requested changes must have been resolved.
- PR must have been approved by every reviewer.
- CI must pass.

## Code Formatting

We use prettier with the default configuration mentioned in the [Solidity Prettier Plugin](https://github.com/prettier-solidity/prettier-plugin-solidity).
We recommend developers using VS Code to set their local config as below:

```
{
	"editor.formatOnSave": true,
	"solidity.formatter": "prettier",
	"editor.defaultFormatter": "esbenp.prettier-vscode"
}
```

In doing so the code will be formatted on each save.

We use Husky hook to format code before being pushed to any remote branch to enforce coding style among all developers.

# Audits

The code concerning the [heap based ordering data-structure](./contracts/HeapOrdering.sol) has been audited by [Omniscia](https://omniscia.io) and the report can be found [online](https://omniscia.io/reports/morpho-heap-ordering-structure/) or in the file [Morpho_Omniscia](./audits/Morpho_Omniscia.pdf).

# Questions

For any questions, you can send an email to [merlin@mopho.best](mailto:merlin@morpho.best) 😊
