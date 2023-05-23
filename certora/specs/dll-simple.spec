methods {
    getValueOf(address) returns (uint256) envfree
    getHead() returns (address) envfree
    getTail() returns (address) envfree
    getNext(address) returns (address) envfree
    getPrev(address) returns (address) envfree
    remove(address) envfree
    insertSorted(address, uint256) envfree
    // added through harness
    getInsertedBefore() returns (address) envfree
    getInsertedAfter() returns (address) envfree
    getPreceding(address) returns (address) envfree
    isForwardLinkedBetween(address, address) returns (bool) envfree
    isDecrSortedFrom(address) returns (bool) envfree
}

// DEFINITIONS

definition isInDLL(address _id) returns bool =
    getValueOf(_id) != 0;

definition isLinked(address _id) returns bool =
    getPrev(_id) != 0 || getNext(_id) != 0;

definition isEmpty(address _id) returns bool =
    ! isInDLL(_id) && ! isLinked(_id);

definition isTwoWayLinked(address first, address second) returns bool =
    first != 0 && second != 0 => (getNext(first) == second <=> getPrev(second) == first);

definition isHeadWellFormed() returns bool =
    getPrev(getHead()) == 0 && (getHead() != 0 => isInDLL(getHead()));

definition isTailWellFormed() returns bool =
    getNext(getTail()) == 0 && (getTail() != 0 => isInDLL(getTail()));

definition hasNoPrevIsHead(address addr) returns bool =
    isInDLL(addr) && getPrev(addr) == 0 => addr == getHead();

definition hasNoNextIsTail(address addr) returns bool =
    isInDLL(addr) && getNext(addr) == 0 => addr == getTail();

function safeAssumptions() {
    requireInvariant zeroEmpty();
    requireInvariant headWellFormed();
    requireInvariant tailWellFormed();
    requireInvariant tipsZero();
}

// INVARIANTS & RULES
// Notice that some invariants have the preservation proof separated for some public functions,
// or even all of the public functions (in that last case they are still relevant for proving
// the property at initial state).

invariant zeroEmpty()
    isEmpty(0)
    filtered { f -> f.selector != insertSorted(address, uint256).selector }

rule zeroEmptyPreservedInsertSorted(address _id, uint256 _value) {
    address prev;

    require isEmpty(0);
    requireInvariant twoWayLinked(prev, getNext(prev));
    requireInvariant noNextIsTail(prev);

    insertSorted(_id, _value);

    require prev == getInsertedAfter();

    assert isEmpty(0);
}

invariant headWellFormed()
    isHeadWellFormed()
    { preserved remove(address _id) {
        requireInvariant zeroEmpty();
        requireInvariant twoWayLinked(getPrev(_id), _id);
        requireInvariant twoWayLinked(_id, getNext(_id));
        requireInvariant linkedIsInDLL(getNext(_id));
      }
    }

invariant tailWellFormed()
    isTailWellFormed()
    filtered { f -> f.selector != insertSorted(address, uint256).selector }
    { preserved remove(address _id) {
        requireInvariant zeroEmpty();
        requireInvariant twoWayLinked(getPrev(_id), _id);
        requireInvariant twoWayLinked(_id, getNext(_id));
        requireInvariant linkedIsInDLL(getPrev(_id));
      }
    }

rule tailWellFormedPreservedInsertSorted(address _id, uint256 _value) {
    address next; address prev;

    require isTailWellFormed();
    requireInvariant zeroEmpty();
    requireInvariant twoWayLinked(getPrev(next), next);
    requireInvariant twoWayLinked(prev, getNext(prev));

    insertSorted(_id, _value);

    require prev == getInsertedAfter();
    require next == getInsertedBefore();

    assert isTailWellFormed();
}

invariant tipsZero()
    getTail() == 0 <=> getHead() == 0
    { preserved remove(address _id) {
        requireInvariant zeroEmpty();
        requireInvariant noNextIsTail(_id);
        requireInvariant noPrevIsHead(_id);
      }
    }

invariant noPrevIsHead(address addr)
    hasNoPrevIsHead(addr)
    filtered { f -> f.selector != insertSorted(address, uint256).selector }
    { preserved remove(address _id) {
        safeAssumptions();
        requireInvariant twoWayLinked(_id, getNext(_id));
        requireInvariant twoWayLinked(getPrev(_id), _id);
        requireInvariant noPrevIsHead(_id);
      }
    }

rule noPrevIsHeadPreservedInsertSorted(address _id, uint256 _value) {
    address addr; address next; address prev;

    require hasNoPrevIsHead(addr);

    safeAssumptions();
    requireInvariant twoWayLinked(getPrev(next), next);
    requireInvariant twoWayLinked(prev, getNext(prev));
    requireInvariant noNextIsTail(prev);

    insertSorted(_id, _value);

    require prev == getInsertedAfter();
    require next == getInsertedBefore();

    assert hasNoPrevIsHead(addr);
}

invariant noNextIsTail(address addr)
    hasNoNextIsTail(addr)
    filtered { f -> f.selector != insertSorted(address, uint256).selector }
    { preserved remove(address _id) {
        safeAssumptions();
        requireInvariant twoWayLinked(_id, getNext(_id));
        requireInvariant twoWayLinked(getPrev(_id), _id);
        requireInvariant noNextIsTail(_id);
      }
    }

rule noNextisTailPreservedInsertSorted(address _id, uint256 _value) {
    address addr; address next; address prev;

    require hasNoNextIsTail(addr);

    safeAssumptions();
    requireInvariant twoWayLinked(getPrev(next), next);
    requireInvariant twoWayLinked(prev, getNext(prev));
    requireInvariant forwardLinked(getTail());

    insertSorted(_id, _value);

    require prev == getInsertedAfter();
    require next == getInsertedBefore();

    assert hasNoNextIsTail(addr);
}

invariant linkedIsInDLL(address addr)
    isLinked(addr) => isInDLL(addr)
    filtered { f -> f.selector != insertSorted(address,uint256).selector }
    { preserved remove(address _id) {
        safeAssumptions();
        requireInvariant twoWayLinked(_id, getNext(_id));
        requireInvariant twoWayLinked(getPrev(_id), _id);
      }
    }

rule linkedIsInDllPreservedInsertSorted(address _id, uint256 _value) {
    address addr; address next; address prev;

    require isLinked(addr) => isInDLL(addr);
    require isLinked(getPrev(next)) => isInDLL(getPrev(next));

    safeAssumptions();
    requireInvariant twoWayLinked(getPrev(next), next);
    requireInvariant noPrevIsHead(next);
    requireInvariant twoWayLinked(prev, getNext(prev));
    requireInvariant noNextIsTail(prev);

    insertSorted(_id, _value);

    require prev == getInsertedAfter();
    require next == getInsertedBefore();

    assert isLinked(addr) => isInDLL(addr);
}

invariant twoWayLinked(address first, address second)
    isTwoWayLinked(first, second)
    filtered { f -> f.selector != insertSorted(address,uint256).selector }
    { preserved remove(address _id) {
        safeAssumptions();
        requireInvariant twoWayLinked(getPrev(_id), _id);
        requireInvariant twoWayLinked(_id, getNext(_id));
      }
    }

rule twoWayLinkedPreservedInsertSorted(address _id, uint256 _value) {
    address first; address second; address next;

    require isTwoWayLinked(first, second);
    require isTwoWayLinked(getPrev(next), next);

    safeAssumptions();
    requireInvariant linkedIsInDLL(_id);

    insertSorted(_id, _value);

    require next == getInsertedBefore();

    assert isTwoWayLinked(first, second);
}

invariant forwardLinked(address addr)
    isInDLL(addr) => isForwardLinkedBetween(getHead(), addr)
    filtered { f -> f.selector != remove(address).selector &&
                    f.selector != insertSorted(address, uint256).selector }

rule forwardLinkedPreservedInsertSorted(address _id, uint256 _value) {
    address addr; address prev;

    require isInDLL(addr) => isForwardLinkedBetween(getHead(), addr);

    safeAssumptions();
    requireInvariant twoWayLinked(prev, getNext(prev));
    requireInvariant noNextIsTail(prev);

    insertSorted(_id, _value);

    require prev == getInsertedAfter();

    assert isInDLL(addr) => isForwardLinkedBetween(getHead(), addr);
}

rule forwardLinkedPreservedRemove(address _id) {
    address addr; address prev;

    require prev == getPreceding(_id);

    require isInDLL(addr) => isForwardLinkedBetween(getHead(), addr);

    safeAssumptions();
    requireInvariant noPrevIsHead(_id);
    requireInvariant twoWayLinked(getPrev(_id), _id);
    requireInvariant twoWayLinked(prev, getNext(prev));
    requireInvariant noNextIsTail(_id);

    remove(_id);

    assert isInDLL(addr) => isForwardLinkedBetween(getHead(), addr);
}

rule removeRemoves(address _id) {
    safeAssumptions();

    remove(_id);

    assert !isInDLL(_id);
}

rule insertSortedInserts(address _id, uint256 _value) {
    safeAssumptions();

    insertSorted(_id, _value);

    assert isInDLL(_id);
}

invariant decrSorted()
    isDecrSortedFrom(getHead())
    { preserved remove(address _id) {
        safeAssumptions();
        requireInvariant noPrevIsHead(_id);
        requireInvariant twoWayLinked(getPrev(_id), _id);
        }
    }

// DERIVED RESULTS

// result: isForwardLinkedBetween(getHead(), getTail())
// explanation: if getTail() == 0, then from tipsZero() we know that getHead() == 0 so the result follows
// otherwise, from tailWellFormed(), we know that isInDLL(getTail()) so the result follows from forwardLinked(getTail()).

// result: forall addr. isForwardLinkedBetween(addr, getTail())
// explanation: it can be obtained from the previous result and forwardLinked.
// Going from head to tail should lead to addr in between (otherwise addr is never reached because there is nothing after the tail).

// result: "BackwardLinked" dual results
// explanation: it can be obtained from ForwardLinked and twoWayLinked.

// result: there is only one list
// explanation: it comes from the fact that every non zero address that is in the DLL is linked to getHead().

// result: there are no cycles that do not contain the 0 address
// explanation: let N be a node in a cycle. Since there is a link from getHead() to N, it means that getHead()
// is part of the cycle. This is absurd because we know from headWellFormed() that the previous element of
// getHead() is the 0 address.
