pragma solidity ^0.4.24;

import "../HarbergerTaxable.sol";

contract HarbergerTaxableMock is HarbergerTaxable {

  function addToValueHeld(address user, uint256 value) internal {
    _addToValueHeld(user, value);
  }

  function subFromValueHeld(address user, uint256 value) internal {
    _subFromValueHeld(user, value);
  }
}
