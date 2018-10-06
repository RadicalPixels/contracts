pragma solidity ^0.4.24;

import "../HarbergerTaxable.sol";

contract HarbergerTaxableMock is HarbergerTaxable {

  constructor(
    uint256 _taxPercentage, 
    address _taxCollector
  )
    public
    HarbergerTaxable(_taxPercentage, _taxCollector)
  {
    taxPercentage = _taxPercentage;
    taxCollector = _taxCollector;
  }

  function addToValueHeld(address user, uint256 value) public {
    _addToValueHeld(user, value);
  }

  function subFromValueHeld(address user, uint256 value) public {
    _subFromValueHeld(user, value);
  }

  function safeTransferTaxes(address user) public {
    require(transferTaxes(user));
  }

  function taxesDue(address user) public view returns (uint256) {
    return _taxesDue(user);
  }

}
