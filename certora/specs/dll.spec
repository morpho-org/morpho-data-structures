methods {
    getValueOf(address) returns (uint256) envfree
    getHead() returns (address) envfree
    getTail() returns (address) envfree
    getNext(address) returns (address) envfree
    getPrev(address) returns (address) envfree
    remove(address) envfree
    insertSorted(address, uint256) envfree
}

// FAILS: circular definition
// definition isForwardLinked(address head, address tail) returns bool =
//     head == tail || getNext(head) != 0 && isForwardLinked(getNext(head), tail);

// invariant DLLisForwardLinked()
//     isForwardLinked(getHead(), getTail())

// FAILS: also a circular definition
// definition decrSortedFromUpper(address head, uint256 upperBound) returns bool =
//     head == 0 || getValueOf(head) <= upperBound && decrSortedFromUpper(getNext(head), getValueOf(head));

// invariant DLLisDecrSorted()
//     decrSortedFromUpper(getHead(), max_uint256)

invariant hasNextExceptTail(address _id)
    getValueOf(_id) != 0 => _id == getTail() || getNext(_id) != 0

invariant hasPrevExceptHead(address _id)
    getValueOf(_id) != 0 => _id == getHead() || getPrev(_id) != 0

invariant nextIsNonNull(address _id)
    getNext(_id) != 0 => getValueOf(_id) != 0
    
invariant prevIsNonNull(address _id)
    getPrev(_id) != 0 => getValueOf(_id) != 0

invariant isDecreasinglySorted(address _id)
    getNext(_id) != 0 => getValueOf(_id) >= getValueOf(getNext(_id))
