pragma solidity ^0.4.24;

import "../HarbingerTaxable.sol";

contract HarbingerTaxableMock is HarbingerTaxable {

  function addToValueHeld(address user, uint256 value) internal {
    _addToValueHeld(user, value);
  }

  function subFromValueHeld(address user, uint256 value) internal {
    _subFromValueHeld(user, value);
  }
}
