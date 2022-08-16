methods {
    getValueOf(address) returns (uint256) envfree
    getHead() returns (address) envfree
    getTail() returns (address) envfree
    getNext(address) returns (address) envfree
    getPrev(address) returns (address) envfree
    remove(address) envfree
    insertSorted(address, uint256) envfree
    // added through harness
    getLength() returns (uint256) envfree
    isForwardLinkedBetween(address, address, uint256) returns (bool) envfree
    isDecrSortedFrom(address, uint256) returns (bool) envfree
}

definition inDLL(address _id) returns bool =
    getValueOf(_id) != 0;

invariant inDLLCharacterization(address _id)
    inDLL(_id) <=> getPrev(_id) != 0 || getNext(_id) != 0

invariant zeroIsNotLinked()
    ! inDLL(0)

invariant zeroPrev(address _id)
    getPrev(_id) == 0 <=> _id == getHead()

invariant zeroNext(address _id)
    getNext(_id) == 0 <=> _id == getTail()

rule DLLisForwardLinkedPreservedRemove() {
    env e; address _id;
    address headBefore = getHead(); 
    address tailBefore = getTail(); 
    uint256 lengthBefore = getLength();
    require isForwardLinkedBetween(headBefore, tailBefore, lengthBefore);
    requireInvariant zeroPrev(_id);
    requireInvariant zeroNext(_id);

    remove(_id);

    address headAfter = getHead(); 
    address tailAfter = getTail(); 
    uint256 lengthAfter = getLength();
    assert isForwardLinkedBetween(headAfter, tailAfter, lengthAfter);
}

// invariant DLLisForwardLinked()
//     isForwardLinkedBetween(getHead(), getTail(), getLength())
//     { preserved { require DLLisForwardLinkedPreservedRemove(); } }


invariant DLLisDecrSorted()
    isDecrSortedFrom(getHead(), getLength())

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
