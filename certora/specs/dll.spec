methods {
    getValueOf(address) returns (uint256) envfree
    getHead() returns (address) envfree
    getTail() returns (address) envfree
    getNext(address) returns (address) envfree
    getPrev(address) returns (address) envfree
    remove(address) envfree
    insertSorted(address, uint256) envfree
    // added through harness
    initialized() returns (bool) envfree
    getInsertBefore() returns (address) envfree
    getInsertAfter() returns (address) envfree
    getLength() returns (uint256) envfree
    isForwardLinkedBetween(address, address, uint256) returns (bool) envfree
    isDecrSortedFrom(address, uint256) returns (bool) envfree
}

// axiom init()
//     ! initialized() => (head == 0 && tail == 0 &&
//                         forall address addr.
//                         dll.accounts[addr].prev == 0 &&
//                         dll.accounts[addr].next == 0 &&
//                         dll.accounts[addr].value == 0)

// DEFINITIONS

definition inDLL(address _id) returns bool =
    getValueOf(_id) != 0;

definition linked(address _id) returns bool =
    getPrev(_id) != 0 || getNext(_id) != 0;

definition isEmpty(address _id) returns bool =
    ! inDLL(_id) && ! linked(_id);

definition isTwoWayLinked(address first, address second) returns bool =
    first != 0 && second != 0 => (getNext(first) == second <=> getPrev(second) == first);


// INVARIANTS & RULES

invariant zeroEmpty()
    isEmpty(0)
    filtered { f -> f.selector != insertSorted(address, uint256).selector }

rule zeroEmptyPreservedInsertSorted(address _id, uint256 _value) {
    env e; address prev;
    address addr;

    require isEmpty(0);
    requireInvariant twoWayLinked(prev, getNext(prev));
    requireInvariant noNextIsTail(prev);

    insertSorted(_id, _value);

    require prev == getInsertAfter();

    assert isEmpty(0);
}

invariant headPrevAndValue()
    getPrev(getHead()) == 0 && (getValueOf(getHead()) == 0 => getHead() == 0)
    { preserved remove(address rem) {
        requireInvariant zeroEmpty();
        requireInvariant twoWayLinked(getPrev(rem), rem);
        requireInvariant twoWayLinked(rem, getNext(rem));
        requireInvariant linkedIsInDLL(getNext(rem));
      }
    }

invariant tailNextAndValue()
    getNext(getTail()) == 0 && (getValueOf(getTail()) == 0 => getTail() == 0)
    filtered { f -> f.selector != insertSorted(address, uint256).selector }
    { preserved remove(address rem) {
        requireInvariant zeroEmpty();
        requireInvariant twoWayLinked(getPrev(rem), rem);
        requireInvariant twoWayLinked(rem, getNext(rem));
        requireInvariant linkedIsInDLL(getPrev(rem));
      }
    }

rule tailNextAndValuePreservedInsertSorted(address _id, uint256 _amount) {
    env e; address next; address prev;

    require getNext(getTail()) == 0 && (getValueOf(getTail()) == 0 => getTail() == 0);
    requireInvariant zeroEmpty();
    requireInvariant twoWayLinked(getPrev(next), next);
    requireInvariant twoWayLinked(prev, getNext(prev));

    insertSorted(_id, _amount);
    
    require prev == getInsertAfter();
    require next == getInsertBefore();
    
    assert getNext(getTail()) == 0 && (getValueOf(getTail()) == 0 => getTail() == 0);
}

invariant noPrevIsHead(address _id)
    inDLL(_id) && getPrev(_id) == 0 => _id == getHead()
    { preserved remove(address rem) {
        requireInvariant zeroEmpty();
        requireInvariant linkedIsInDLL(_id);
        requireInvariant twoWayLinked(rem, getNext(rem));
        requireInvariant twoWayLinked(getPrev(rem), rem);
      }
    }

invariant noNextIsTail(address _id)
    inDLL(_id) && getNext(_id) == 0 => _id == getTail()

invariant linkedIsInDLL(address _id)
    linked(_id) => inDLL(_id)
    filtered { f -> f.selector != insertSorted(address,uint256).selector }
    { preserved remove(address rem) {
        requireInvariant zeroEmpty();
        requireInvariant twoWayLinked(rem, getNext(rem));
        requireInvariant twoWayLinked(getPrev(rem), rem);
      }
    }

rule linkedIsInDllPreservedInsertSorted(address _id, uint256 _value) {
    env e; address next; address prev;
    address addr;

    require linked(addr) => inDLL(addr);
    require linked(getPrev(next)) => inDLL(getPrev(next));
    requireInvariant zeroEmpty();
    requireInvariant headPrevAndValue();
    requireInvariant tailNextAndValue();
    requireInvariant twoWayLinked(getPrev(next), next);
    requireInvariant noPrevIsHead(next);
    requireInvariant twoWayLinked(prev, getNext(prev));
    requireInvariant noNextIsTail(prev);

    insertSorted(_id, _value);

    require prev == getInsertAfter();
    require next == getInsertBefore();

    assert linked(addr) => inDLL(addr);
}

invariant twoWayLinked(address first, address second)
    isTwoWayLinked(first, second)
    filtered { f -> f.selector != insertSorted(address,uint256).selector }
    { preserved remove(address rem) {
        requireInvariant zeroEmpty();
        requireInvariant twoWayLinked(getPrev(rem), rem);
        requireInvariant twoWayLinked(rem, getNext(rem));
      }
    }

rule twoWayLinkedPreservedInsertSorted(address _id, uint256 _value) {
    env e; address next;
    address first; address second;

    require isTwoWayLinked(first, second);
    require isTwoWayLinked(getPrev(next), next);
    require isTwoWayLinked(next, getNext(next));
    requireInvariant zeroEmpty();
    requireInvariant headPrevAndValue();
    requireInvariant tailNextAndValue();
    requireInvariant linkedIsInDLL(_id);

    insertSorted(_id, _value);

    require next == getInsertBefore();

    assert isTwoWayLinked(first, second);
}

// rule isForwardLinkedPreservedRemove() {
//     env e; address _id;
//     address headBefore = getHead();
//     address tailBefore = getTail();
//     uint256 lengthBefore = getLength();
//     require isForwardLinkedBetween(headBefore, tailBefore, lengthBefore);
//     requireInvariant noPrevIsHead(_id);
//     requireInvariant noNextIsTail(_id);
//     requireInvariant zeroNotInDLL();

//     remove(_id);

//     address headAfter = getHead();
//     address tailAfter = getTail();
//     uint256 lengthAfter = getLength();
//     assert isForwardLinkedBetween(headAfter, tailAfter, lengthAfter);
// }

invariant DLLisForwardLinked()
    isForwardLinkedBetween(getHead(), getTail(), getLength())
    { preserved remove(address rem) {
          requireInvariant zeroEmpty();
          requireInvariant noPrevIsHead(rem);
          requireInvariant noNextIsTail(rem);
        }
    }

invariant DLLisDecrSorted()
    isDecrSortedFrom(getHead(), getLength())
