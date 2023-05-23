methods {
    getValueOf(address) returns (uint256) envfree
    getHead() returns (address) envfree
    getTail() returns (address) envfree
    getNext(address) returns (address) envfree
    getPrev(address) returns (address) envfree
    remove(address) envfree
    insertSorted(address, uint256, uint256) envfree
    // added through harness
    getInsertedBefore() returns (address) envfree
    getInsertedAfter() returns (address) envfree
    getLength() returns (uint256) envfree
    getPreceding(address) returns (address) envfree
    isForwardLinkedBetween(address, address) returns (bool) envfree
    greaterThanUpTo(uint256, address, uint256) returns (bool) envfree
    lenUpTo(address) returns (uint256) envfree

    maxIterations() returns (uint256) envfree => NONDET
}

// DEFINITIONS

definition isInDLL(address id) returns bool =
    getValueOf(id) != 0;

definition isLinked(address id) returns bool =
    getPrev(id) != 0 || getNext(id) != 0;

definition isEmpty(address id) returns bool =
    ! isInDLL(id) && ! isLinked(id);

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
    filtered { f -> f.selector != insertSorted(address, uint256, uint256).selector }

rule zeroEmptyPreservedInsertSorted(address id, uint256 value) {
    address prev;

    require isEmpty(0);

    requireInvariant twoWayLinked(prev, getNext(prev));
    requireInvariant noNextIsTail(prev);
    requireInvariant tipsZero();

    insertSorted(id, value, maxIterations());

    require prev == getInsertedAfter();

    assert isEmpty(0);
}

invariant headWellFormed()
    isHeadWellFormed()
    { preserved remove(address id) {
        requireInvariant zeroEmpty();
        requireInvariant twoWayLinked(getPrev(id), id);
        requireInvariant twoWayLinked(id, getNext(id));
        requireInvariant linkedIsInDLL(getNext(id));
      }
    }

invariant tailWellFormed()
    isTailWellFormed()
    filtered { f -> f.selector != insertSorted(address, uint256, uint256).selector }
    { preserved remove(address id) {
        requireInvariant zeroEmpty();
        requireInvariant twoWayLinked(getPrev(id), id);
        requireInvariant twoWayLinked(id, getNext(id));
        requireInvariant linkedIsInDLL(getPrev(id));
      }
    }

rule tailWellFormedPreservedInsertSorted(address id, uint256 value) {
    address next; address prev;

    require isTailWellFormed();

    requireInvariant zeroEmpty();
    requireInvariant twoWayLinked(getPrev(next), next);
    requireInvariant twoWayLinked(prev, getNext(prev));

    insertSorted(id, value, maxIterations());

    require prev == getInsertedAfter();
    require next == getInsertedBefore();

    assert isTailWellFormed();
}

invariant tipsZero()
    getTail() == 0 <=> getHead() == 0
    { preserved remove(address id) {
        requireInvariant zeroEmpty();
        requireInvariant noNextIsTail(id);
        requireInvariant noPrevIsHead(id);
      }
    }

invariant noPrevIsHead(address addr)
    hasNoPrevIsHead(addr)
    filtered { f -> f.selector != insertSorted(address, uint256, uint256).selector }
    { preserved remove(address id) {
        safeAssumptions();
        requireInvariant twoWayLinked(id, getNext(id));
        requireInvariant twoWayLinked(getPrev(id), id);
        requireInvariant noPrevIsHead(id);
      }
    }

rule noPrevIsHeadPreservedInsertSorted(address id, uint256 value) {
    address addr; address next; address prev;

    require hasNoPrevIsHead(addr);

    safeAssumptions();
    requireInvariant twoWayLinked(getPrev(next), next);
    requireInvariant twoWayLinked(prev, getNext(prev));
    requireInvariant noNextIsTail(prev);

    insertSorted(id, value, maxIterations());

    require prev == getInsertedAfter();
    require next == getInsertedBefore();

    assert hasNoPrevIsHead(addr);
}

invariant noNextIsTail(address addr)
    hasNoNextIsTail(addr)
    filtered { f -> f.selector != insertSorted(address, uint256, uint256).selector }
    { preserved remove(address id) {
        safeAssumptions();
        requireInvariant twoWayLinked(id, getNext(id));
        requireInvariant twoWayLinked(getPrev(id), id);
        requireInvariant noNextIsTail(id);
      }
    }

rule noNextisTailPreservedInsertSorted(address id, uint256 value) {
    address addr; address next; address prev;

    require hasNoNextIsTail(addr);

    safeAssumptions();
    requireInvariant twoWayLinked(getPrev(next), next);
    requireInvariant twoWayLinked(prev, getNext(prev));
    requireInvariant forwardLinked(getTail());

    insertSorted(id, value, maxIterations());

    require prev == getInsertedAfter();
    require next == getInsertedBefore();

    assert hasNoNextIsTail(addr);
}

invariant linkedIsInDLL(address addr)
    isLinked(addr) => isInDLL(addr)
    filtered { f -> f.selector != insertSorted(address, uint256, uint256).selector }
    { preserved remove(address id) {
        safeAssumptions();
        requireInvariant twoWayLinked(id, getNext(id));
        requireInvariant twoWayLinked(getPrev(id), id);
      }
    }

rule linkedIsInDllPreservedInsertSorted(address id, uint256 value) {
    address addr; address next; address prev;

    require isLinked(addr) => isInDLL(addr);
    require isLinked(getPrev(next)) => isInDLL(getPrev(next));

    safeAssumptions();
    requireInvariant twoWayLinked(getPrev(next), next);
    requireInvariant noPrevIsHead(next);
    requireInvariant twoWayLinked(prev, getNext(prev));
    requireInvariant noNextIsTail(prev);

    insertSorted(id, value, maxIterations());

    require prev == getInsertedAfter();
    require next == getInsertedBefore();

    assert isLinked(addr) => isInDLL(addr);
}

invariant twoWayLinked(address first, address second)
    isTwoWayLinked(first, second)
    filtered { f -> f.selector != insertSorted(address, uint256, uint256).selector }
    { preserved remove(address id) {
        safeAssumptions();
        requireInvariant twoWayLinked(getPrev(id), id);
        requireInvariant twoWayLinked(id, getNext(id));
      }
    }

rule twoWayLinkedPreservedInsertSorted(address id, uint256 value) {
    address first; address second; address next;

    require isTwoWayLinked(first, second);
    require isTwoWayLinked(getPrev(next), next);

    safeAssumptions();
    requireInvariant linkedIsInDLL(id);

    insertSorted(id, value, maxIterations());

    require next == getInsertedBefore();

    assert isTwoWayLinked(first, second);
}

invariant forwardLinked(address addr)
    isInDLL(addr) => isForwardLinkedBetween(getHead(), addr)
    filtered { f -> f.selector != remove(address).selector &&
                    f.selector != insertSorted(address, uint256, uint256).selector }

rule forwardLinkedPreservedInsertSorted(address id, uint256 value) {
    address addr; address prev;

    require isInDLL(addr) => isForwardLinkedBetween(getHead(), addr);
    require isInDLL(getTail()) => isForwardLinkedBetween(getHead(), getTail());

    safeAssumptions();
    requireInvariant linkedIsInDLL(id);
    requireInvariant twoWayLinked(prev, getNext(prev));
    requireInvariant noNextIsTail(prev);

    insertSorted(id, value, maxIterations());

    require prev == getInsertedAfter();

    assert isInDLL(addr) => isForwardLinkedBetween(getHead(), addr);
}

rule forwardLinkedPreservedRemove(address id) {
    address addr; address prev;

    require prev == getPreceding(id);

    require isInDLL(addr) => isForwardLinkedBetween(getHead(), addr);

    safeAssumptions();
    requireInvariant noPrevIsHead(id);
    requireInvariant twoWayLinked(getPrev(id), id);
    requireInvariant twoWayLinked(prev, getNext(prev));
    requireInvariant noNextIsTail(id);

    remove(id);

    assert isInDLL(addr) => isForwardLinkedBetween(getHead(), addr);
}

rule removeRemoves(address id) {
    safeAssumptions();

    remove(id);

    assert !isInDLL(id);
}

rule insertSortedInserts(address id, uint256 value) {
    safeAssumptions();

    insertSorted(id, value, maxIterations());

    assert isInDLL(id);
}

rule insertSortedDecreasingOrder(address id, uint256 value) {
    address prev;

    uint256 maxIter = maxIterations();

    safeAssumptions();
    requireInvariant twoWayLinked(prev, getNext(prev));
    requireInvariant linkedIsInDLL(id);

    insertSorted(id, value, maxIter);

    require prev == getInsertedAfter();

    uint256 positionInDLL = lenUpTo(id);

    assert positionInDLL > maxIter => greaterThanUpTo(value, 0, maxIter) && id == getTail();
    assert positionInDLL <= maxIter => greaterThanUpTo(value, id, getLength()) && value > getValueOf(getNext(id));
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
