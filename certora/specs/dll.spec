methods {
    getValueOf(address) returns (uint256) envfree
    getHead() returns (address) envfree
    getTail() returns (address) envfree
    getNext(address) returns (address) envfree
    getPrev(address) returns (address) envfree
    remove(address) envfree
    insert(address, uint256) envfree
}

// FAILS: circular definition
// definition isForwardLinked(address head, address tail) returns bool =
//     head == tail || getNext(head) != 0 && isForwardLinked(getNext(head), tail);

// invariant DLLisForwardLinked()
//     isLinked(getHead(), getTail())

// FAILS: also a circular definition
// definition decrSortedFromUpper(address head, uint256 upperBound) returns bool =
//     head == 0 || getValueOf(head) <= upperBound && decrSortedFromUpper(getNext(head), getValueOf(head));

// invariant DLLisDecrSorted()
//     decrSortedFromUpper(getHead(), max_uint256)
