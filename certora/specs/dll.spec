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

definition linked(address _id) returns bool =
    getPrev(_id) != 0 || getNext(_id) != 0;

invariant zeroNotInDLL()
    ! inDLL(0)

invariant headPrevIsZero()
    getPrev(getHead()) == 0 && (getValueOf(getHead()) == 0 => getHead() == 0)
    { preserved remove(address rem) {
        requireInvariant twoWayLinked(getPrev(rem), rem);
        requireInvariant twoWayLinked(rem, getNext(rem));
        requireInvariant zeroNotInDLL();
        requireInvariant linkedIsInDLL(getNext(rem));
      }
    }

invariant tailNextIsZero()
    getNext(getTail()) == 0 && (getValueOf(getTail()) == 0 => getTail() == 0)
    { preserved remove(address rem) {
        requireInvariant twoWayLinked(getPrev(rem), rem);
        requireInvariant twoWayLinked(rem, getNext(rem));
        requireInvariant zeroNotInDLL();
        requireInvariant linkedIsInDLL(getPrev(rem));
      } 
      preserved insertSorted(address id, uint256 amount) {
        requireInvariant twoWayLinked(id, getNext(id));
        requireInvariant twoWayLinked(getPrev(id), id);
        requireInvariant twoWayLinked(getTail(), getNext(getTail()));
        requireInvariant zeroNotInDLL();
      }
    }

invariant tipIsZero()
    getHead() == 0 <=> getTail() == 0

invariant zeroIsNotLinked()
    getPrev(0) == 0 && getNext(0) == 0
    { preserved { requireInvariant tipIsZero(); } }

ghost address insertBefore;
hook Sstore currentContract.dll.insertBefore address next STORAGE {
    require insertBefore == next;
}

definition isTwoWayLinked(address first, address second) returns bool =
    first != 0 && second != 0 => (getNext(first) == second <=> getPrev(second) == first);

invariant twoWayLinked(address first, address second)
    isTwoWayLinked(first, second)
    filtered { f -> f.selector != insertSorted(address,uint256).selector } 
    { preserved remove(address rem) { 
        requireInvariant twoWayLinked(getPrev(rem), rem);
        requireInvariant twoWayLinked(rem, getNext(rem));
        requireInvariant zeroNotInDLL();
      }
    }

rule insertSortedTwoWayLinked(address _id, uint256 _value) {
    env e; address next;
    address first; address second;

    require isTwoWayLinked(first, second);
    require isTwoWayLinked(getPrev(next), next);
    require isTwoWayLinked(next, getNext(next));

    insertSorted(_id, _value);

    // require next == insertBefore;

    assert isTwoWayLinked(first, second);
}

invariant bothWayLinked(address _id)
    isTwoWayLinked(_id, getNext(_id)) && isTwoWayLinked(getPrev(_id), _id)

invariant linkedIsInDLL(address _id)
    linked(_id) => inDLL(_id)
    { preserved remove(address rem) {
        requireInvariant twoWayLinked(rem, getNext(rem));
        requireInvariant twoWayLinked(getPrev(rem), rem);
        requireInvariant zeroNotInDLL();
      }
      preserved {
        requireInvariant zeroIsNotLinked();
        requireInvariant zeroNotInDLL();
      }
    }

invariant hasNextExceptTail(address _id)
    inDLL(_id) => _id == getTail() || getNext(_id) != 0

invariant hasPrevExceptHead(address _id)
    inDLL(_id) => _id == getHead() || getPrev(_id) != 0

invariant headPrev(address _id)
    getValueOf(_id) != 0 && getPrev(_id) == 0 => _id == getHead()
    { preserved remove(address rem) {
        requireInvariant linkedIsInDLL(_id);
        requireInvariant twoWayLinked(rem, getNext(rem));
        requireInvariant twoWayLinked(getPrev(rem), rem);
        requireInvariant zeroIsNotLinked();
      }
    }

invariant tailNext(address _id)
    getValueOf(_id) != 0 && getNext(_id) == 0 => _id == getTail()

rule DLLisForwardLinkedPreservedRemove() {
    env e; address _id;
    address headBefore = getHead(); 
    address tailBefore = getTail(); 
    uint256 lengthBefore = getLength();
    require isForwardLinkedBetween(headBefore, tailBefore, lengthBefore);
    requireInvariant headPrev(_id);
    requireInvariant tailNext(_id);
    requireInvariant zeroNotInDLL(); 

    remove(_id);

    address headAfter = getHead(); 
    address tailAfter = getTail(); 
    uint256 lengthAfter = getLength();
    assert isForwardLinkedBetween(headAfter, tailAfter, lengthAfter);
}

invariant DLLisForwardLinked()
    isForwardLinkedBetween(getHead(), getTail(), getLength())
    { preserved remove(address rem) 
        { requireInvariant headPrev(rem);
          requireInvariant tailNext(rem);
          requireInvariant zeroNotInDLL(); }
    }

invariant DLLisDecrSorted()
    isDecrSortedFrom(getHead(), getLength())
