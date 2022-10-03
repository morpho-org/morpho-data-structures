methods {
    getValueOf(address) returns (uint256) envfree
    getHead() returns (address) envfree
    getTail() returns (address) envfree
    getNext(address) returns (address) envfree
    getPrev(address) returns (address) envfree
    remove(address) envfree
    insertSorted(address, uint256) envfree
    // added through harness
    getInsertBefore() returns (address) envfree
    getInsertAfter() returns (address) envfree
    prevFromHead(address) returns (address) envfree
    isForwardLinkedBetween(address, address) returns (bool) envfree
    isDecrSortedFrom(address) returns (bool) envfree
}

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
    getPrev(getHead()) == 0 && (getHead() != 0 => inDLL(getHead()))
    { preserved remove(address rem) {
        requireInvariant zeroEmpty();
        requireInvariant twoWayLinked(getPrev(rem), rem);
        requireInvariant twoWayLinked(rem, getNext(rem));
        requireInvariant linkedIsInDLL(getNext(rem));
      }
    }

invariant tailNextAndValue()
    getNext(getTail()) == 0 && (getTail() != 0 => inDLL(getTail()))
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

    require getNext(getTail()) == 0 && (getTail() != 0 => inDLL(getTail()));
    requireInvariant zeroEmpty();
    requireInvariant twoWayLinked(getPrev(next), next);
    requireInvariant twoWayLinked(prev, getNext(prev));

    insertSorted(_id, _amount);
    
    require prev == getInsertAfter();
    require next == getInsertBefore();
    
    assert getNext(getTail()) == 0 && (getTail() != 0 => inDLL(getTail()));
}

invariant noPrevIsHead(address _id)
    inDLL(_id) && getPrev(_id) == 0 => _id == getHead()
    filtered { f -> f.selector != insertSorted(address, uint256).selector }
    { preserved remove(address rem) {
        requireInvariant zeroEmpty();
        requireInvariant linkedIsInDLL(_id);
        requireInvariant twoWayLinked(rem, getNext(rem));
        requireInvariant twoWayLinked(getPrev(rem), rem);
        requireInvariant noPrevIsHead(rem);
      }
    }

rule noPrevIsHeadPreservedInsertSorted(address _id, uint256 _amount) {
    env e; address next; address prev;
    address addr;

    require inDLL(addr) && getPrev(addr) == 0 => addr == getHead();
    requireInvariant zeroEmpty();
    requireInvariant twoWayLinked(getPrev(next), next);
    requireInvariant twoWayLinked(prev, getNext(prev));
    requireInvariant noNextIsTail(prev);

    insertSorted(_id, _amount);
    
    require prev == getInsertAfter();
    require next == getInsertBefore();
    
    assert inDLL(addr) && getPrev(addr) == 0 => addr == getHead();
}

invariant noNextIsTail(address _id)
    inDLL(_id) && getNext(_id) == 0 => _id == getTail()
    filtered { f -> f.selector != insertSorted(address, uint256).selector }
    { preserved remove(address rem) {
        requireInvariant zeroEmpty();
        requireInvariant linkedIsInDLL(_id);
        requireInvariant twoWayLinked(rem, getNext(rem));
        requireInvariant twoWayLinked(getPrev(rem), rem);
        requireInvariant noNextIsTail(rem);
      }
    }

rule noNextisTailPreservedInsertSorted(address _id, uint256 _amount) {
    env e; address next; address prev;
    address addr;

    require inDLL(addr) && getNext(addr) == 0 => addr == getTail();
    requireInvariant zeroEmpty();
    requireInvariant twoWayLinked(getPrev(next), next);
    requireInvariant twoWayLinked(prev, getNext(prev));
    requireInvariant DLLisForwardLinked();

    insertSorted(_id, _amount);
    
    require prev == getInsertAfter();
    require next == getInsertBefore();
    
    assert inDLL(addr) && getNext(addr) == 0 => addr == getTail();
}

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
    requireInvariant zeroEmpty();
    requireInvariant headPrevAndValue();
    requireInvariant tailNextAndValue();
    requireInvariant linkedIsInDLL(_id);

    insertSorted(_id, _value);

    require next == getInsertBefore();

    assert isTwoWayLinked(first, second);
}

invariant DLLisForwardLinked(address addr)
    inDLL(addr) => isForwardLinkedBetween(getHead(), addr)
    filtered { f -> f.selector != remove(address).selector &&
                    f.selector != insertSorted(address, uint256).selector }

rule DLLisForwardLinkedPreservedInsertSorted(address addr) {
    env e; address id; uint256 amount; address prev;

    require inDLL(addr) => isForwardLinkedBetween(getHead(), addr);
    requireInvariant zeroEmpty();
    requireInvariant headPrevAndValue();
    requireInvariant tailNextAndValue();
    requireInvariant twoWayLinked(prev, getNext(prev));
    requireInvariant noNextIsTail(prev);

    insertSorted(id, amount);

    require prev == getInsertAfter();

    assert inDLL(addr) => isForwardLinkedBetween(getHead(), addr);
}

rule DLLisForwardLinkedPreservedRemove(address addr) {
    env e; address rem; address prev;

    require prev == prevFromHead(rem);

    require inDLL(addr) => isForwardLinkedBetween(getHead(), addr);
    requireInvariant zeroEmpty();
    requireInvariant headPrevAndValue();
    requireInvariant tailNextAndValue();
    requireInvariant noPrevIsHead(rem);
    requireInvariant twoWayLinked(getPrev(rem), rem);
    requireInvariant twoWayLinked(prev, getNext(prev));
    requireInvariant noNextIsTail(rem);

    remove(rem);

    assert inDLL(addr) => isForwardLinkedBetween(getHead(), addr);
}

invariant DLLisDecrSorted()
    isDecrSortedFrom(getHead())
    { preserved remove(address rem) {
        requireInvariant zeroEmpty();
        requireInvariant noPrevIsHead(rem);
        requireInvariant twoWayLinked(getPrev(rem), rem);
        }
    }
