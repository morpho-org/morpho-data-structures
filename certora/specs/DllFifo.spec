methods {
    function getValueOf(address) external returns (uint256) envfree;
    function getHead() external returns (address) envfree;
    function getTail() external returns (address) envfree;
    function getNext(address) external returns (address) envfree;
    function getPrev(address) external returns (address) envfree;
    function remove(address) external envfree;
    function insertSorted(address, uint256, uint256) external envfree;
    // added through harness
    function getInsertedBefore() external returns (address) envfree;
    function getInsertedAfter() external returns (address) envfree;
    function getLength() external returns (uint256) envfree;
    function getPreceding(address) external returns (address) envfree;
    function isForwardLinkedBetween(address, address) external returns (bool) envfree;
    function greaterThanUpTo(uint256, address, uint256) external returns (bool) envfree;
    function lenUpTo(address) external returns (uint256) envfree;

    function maxIterations() external returns (uint256) envfree => NONDET;
}

// DEFINITIONS

definition isInDll(address id) returns bool =
    getValueOf(id) != 0;

definition isLinked(address id) returns bool =
    id != 0 && (getPrev(id) != 0 || getNext(id) != 0 || getPrev(0) == id || getNext(0) == id);

definition isEmptyEquiv() returns bool =
    getNext(0) == 0 <=> getPrev(0) == 0;

definition isLinkedToZero(address id) returns bool =
    isLinked(id) =>
    (getNext(id) == 0 => getPrev(0) == id) &&
    (getPrev(id) == 0 => getNext(0) == id);

definition isTwoWayLinked(address first, address second) returns bool =
    (first != 0  => getPrev(second) == first => getNext(first) == second) &&
    (second != 0 => getNext(first) == second => getPrev(second) == first);

definition isHeadWellFormed() returns bool =
    getPrev(getHead()) == 0 && (getHead() != 0 => isInDll(getHead()));

definition isTailWellFormed() returns bool =
    getNext(getTail()) == 0 && (getTail() != 0 => isInDll(getTail()));

definition hasNoPrevIsHead(address addr) returns bool =
    isInDll(addr) && getPrev(addr) == 0 => addr == getHead();

definition hasNoNextIsTail(address addr) returns bool =
    isInDll(addr) && getNext(addr) == 0 => addr == getTail();

function safeAssumptions() {
    requireInvariant emptyZero();
    requireInvariant emptyEquiv();
    requireInvariant headWellFormed();
    requireInvariant tailWellFormed();
    requireInvariant tipsZero();
}

// INVARIANTS & RULES
// Notice that some invariants have the preservation proof separated for some public functions,
// or even all of the public functions (in that last case they are still relevant for proving
// the property at initial state).

invariant emptyZero()
    ! isInDll(0);

invariant emptyEquiv()
    isEmptyEquiv()
    { preserved remove(address id) {
        safeAssumptions();
        requireInvariant twoWayLinked(getPrev(id), id);
        requireInvariant twoWayLinked(id, getNext(id));
        requireInvariant linkedToZero(id);
        requireInvariant inDllIsLinked(id);
      }
    }

invariant linkedToZero(address addr)
    isLinkedToZero(addr)
    filtered { f -> f.selector != sig:insertSorted(address, uint256, uint256).selector }
    { preserved remove(address id) {
        requireInvariant twoWayLinked(getPrev(id), id);
        requireInvariant twoWayLinked(id, getNext(id));
        requireInvariant twoWayLinked(0, id);
        requireInvariant twoWayLinked(id, 0);
        requireInvariant linkedToZero(id);
        requireInvariant inDllIsLinked(id);
      }
    }

rule linkedToZeroPreservedInsertSorted(address id, uint256 value) {
    address addr; address prev; address next;

    require isLinkedToZero(addr);

    safeAssumptions();
    requireInvariant twoWayLinked(getPrev(next), next);
    requireInvariant twoWayLinked(prev, getNext(prev));
    requireInvariant linkedToZero(prev);
    requireInvariant inDllIsLinked(prev);

    insertSorted(id, value, maxIterations());

    require prev == getInsertedAfter();
    require next == getInsertedBefore();

    assert isLinkedToZero(addr);
}

invariant headWellFormed()
    isHeadWellFormed()
    filtered { f -> f.selector != sig:insertSorted(address, uint256, uint256).selector }
    { preserved remove(address id) {
        requireInvariant twoWayLinked(getPrev(id), id);
        requireInvariant twoWayLinked(id, getNext(id));
        requireInvariant linkedIsInDll(getNext(id));
        requireInvariant linkedToZero(id);
      }
    }

rule headWellFormedPreservedInsertSorted(address id, uint256 value) {
    address prev; address next;

    require isHeadWellFormed();

    requireInvariant twoWayLinked(getPrev(next), next);
    requireInvariant twoWayLinked(prev, getNext(prev));

    insertSorted(id, value, maxIterations());

    require prev == getInsertedAfter();
    require next == getInsertedBefore();

    assert isHeadWellFormed();
}

invariant tailWellFormed()
    isTailWellFormed()
    filtered { f -> f.selector != sig:insertSorted(address, uint256, uint256).selector }
    { preserved remove(address id) {
        requireInvariant twoWayLinked(getPrev(id), id);
        requireInvariant twoWayLinked(id, getNext(id));
        requireInvariant linkedIsInDll(getPrev(id));
        requireInvariant linkedToZero(id);
      }
    }

rule tailWellFormedPreservedInsertSorted(address id, uint256 value) {
    address prev; address next;

    require isTailWellFormed();

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
        requireInvariant noNextIsTail(id);
        requireInvariant noPrevIsHead(id);
      }
    }

invariant noPrevIsHead(address addr)
    hasNoPrevIsHead(addr)
    filtered { f -> f.selector != sig:insertSorted(address, uint256, uint256).selector }
    { preserved remove(address id) {
        safeAssumptions();
        requireInvariant twoWayLinked(id, getNext(id));
        requireInvariant twoWayLinked(getPrev(id), id);
        requireInvariant noPrevIsHead(id);
      }
    }

rule noPrevIsHeadPreservedInsertSorted(address id, uint256 value) {
    address addr; address prev; address next;

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
    filtered { f -> f.selector != sig:insertSorted(address, uint256, uint256).selector }
    { preserved remove(address id) {
        safeAssumptions();
        requireInvariant twoWayLinked(id, getNext(id));
        requireInvariant twoWayLinked(getPrev(id), id);
        requireInvariant noNextIsTail(id);
      }
    }

rule noNextisTailPreservedInsertSorted(address id, uint256 value) {
    address addr; address prev; address next;

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

invariant inDllIsLinked(address addr)
    isInDll(addr) => isLinked(addr)
    filtered { f -> f.selector != sig:insertSorted(address, uint256, uint256).selector }
    { preserved remove(address id) {
        requireInvariant twoWayLinked(getPrev(id), id);
        requireInvariant twoWayLinked(id, getNext(id));
        requireInvariant linkedToZero(id);
        requireInvariant inDllIsLinked(id);
      }
    }

rule inDllIsLinkedPreservedInsertSorted(address id, uint256 value) {
    address addr; address prev; address next;

    require isInDll(addr) => isLinked(addr);

    safeAssumptions();
    requireInvariant twoWayLinked(getPrev(next), next);
    requireInvariant twoWayLinked(prev, getNext(prev));
    requireInvariant linkedToZero(prev);
    requireInvariant inDllIsLinked(prev);

    insertSorted(id, value, maxIterations());

    require prev == getInsertedAfter();
    require next == getInsertedBefore();

    assert isInDll(addr) => isLinked(addr);
}

invariant linkedIsInDll(address addr)
    isLinked(addr) => isInDll(addr)
    filtered { f -> f.selector != sig:insertSorted(address, uint256, uint256).selector }
    { preserved remove(address id) {
        safeAssumptions();
        requireInvariant twoWayLinked(id, getNext(id));
        requireInvariant twoWayLinked(getPrev(id), id);
      }
    }

rule linkedIsInDllPreservedInsertSorted(address id, uint256 value) {
    address addr; address prev; address next;

    require isLinked(addr) => isInDll(addr);
    require isLinked(getPrev(next)) => isInDll(getPrev(next));

    safeAssumptions();
    requireInvariant twoWayLinked(getPrev(next), next);
    requireInvariant noPrevIsHead(next);
    requireInvariant twoWayLinked(prev, getNext(prev));
    requireInvariant noNextIsTail(prev);

    insertSorted(id, value, maxIterations());

    require prev == getInsertedAfter();
    require next == getInsertedBefore();

    assert isLinked(addr) => isInDll(addr);
}

invariant twoWayLinked(address first, address second)
    isTwoWayLinked(first, second)
    filtered { f -> f.selector != sig:insertSorted(address, uint256, uint256).selector }
    { preserved remove(address id) {
        safeAssumptions();
        requireInvariant twoWayLinked(getPrev(id), id);
        requireInvariant twoWayLinked(id, getNext(id));
      }
    }

rule twoWayLinkedPreservedInsertSorted(address id, uint256 value) {
    address first; address second; address prev; address next;

    require isTwoWayLinked(first, second);
    require isTwoWayLinked(getPrev(next), next);
    require isTwoWayLinked(prev, getNext(prev));

    safeAssumptions();
    requireInvariant linkedIsInDll(id);

    insertSorted(id, value, maxIterations());

    require prev == getInsertedAfter();
    require next == getInsertedBefore();

    assert isTwoWayLinked(first, second);
}

invariant forwardLinked(address addr)
    isInDll(addr) => isForwardLinkedBetween(getHead(), addr)
    filtered { f -> f.selector != sig:remove(address).selector &&
                    f.selector != sig:insertSorted(address, uint256, uint256).selector }

rule forwardLinkedPreservedInsertSorted(address id, uint256 value) {
    address addr; address prev;

    require isInDll(addr) => isForwardLinkedBetween(getHead(), addr);
    require isInDll(getTail()) => isForwardLinkedBetween(getHead(), getTail());

    safeAssumptions();
    requireInvariant linkedIsInDll(id);
    requireInvariant twoWayLinked(prev, getNext(prev));
    requireInvariant noNextIsTail(prev);

    insertSorted(id, value, maxIterations());

    require prev == getInsertedAfter();

    assert isInDll(addr) => isForwardLinkedBetween(getHead(), addr);
}

rule forwardLinkedPreservedRemove(address id) {
    address addr; address prev;

    require prev == getPreceding(id);

    require isInDll(addr) => isForwardLinkedBetween(getHead(), addr);

    safeAssumptions();
    requireInvariant noPrevIsHead(id);
    requireInvariant twoWayLinked(getPrev(id), id);
    requireInvariant twoWayLinked(prev, getNext(prev));
    requireInvariant noNextIsTail(id);

    remove(id);

    assert isInDll(addr) => isForwardLinkedBetween(getHead(), addr);
}

rule removeRemoves(address id) {
    safeAssumptions();

    remove(id);

    assert !isInDll(id);
}

rule insertSortedInserts(address id, uint256 value) {
    safeAssumptions();

    insertSorted(id, value, maxIterations());

    assert isInDll(id);
}

rule insertSortedDecreasingOrder(address id, uint256 value) {
    address prev;

    uint256 maxIter = maxIterations();

    safeAssumptions();
    requireInvariant twoWayLinked(prev, getNext(prev));
    requireInvariant linkedIsInDll(id);

    insertSorted(id, value, maxIter);

    require prev == getInsertedAfter();

    uint256 positionInDll = lenUpTo(id);
    assert positionInDll > maxIter => greaterThanUpTo(value, 0, maxIter) && id == getTail();
    assert positionInDll <= maxIter => greaterThanUpTo(value, id, getLength()) && value > getValueOf(getNext(id));
}

// DERIVED RESULTS

// result: isForwardLinkedBetween(getHead(), getTail())
// explanation: if getTail() == 0, then from tipsZero() we know that getHead() == 0 so the result follows.
// Otherwise, from tailWellFormed(), we know that isInDll(getTail()) so the result follows from forwardLinked(getTail()).

// result: forall addr. isInDll(addr) => isForwardLinkedBetween(addr, getTail())
// explanation: it can be obtained from the previous result and forwardLinked.
// Going from head to tail should lead to addr in between (otherwise addr is never reached because there is nothing after the tail).

// result: "BackwardLinked" dual results
// explanation: it can be obtained from ForwardLinked and twoWayLinked.

// result: there is only one list
// explanation: it comes from the fact that every non zero address that is in the DLL is linked to getHead().

// result: there are no cycles that do not contain the 0 address
// explanation: let N be a node in a cycle. Since there is a link from getHead() to N, it means that getHead() is part of the cycle.
// The result follows because we know from headWellFormed() that the previous element of getHead() is the 0 address.
