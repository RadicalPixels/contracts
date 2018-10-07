pragma solidity ^0.4.24;

import "../HarbergerTaxable.sol";
import "zos-lib/contracts/migrations/Migratable.sol";

contract HarbergerTaxableMock is Migratable, HarbergerTaxable {

  function initialize(
    uint256 _taxPercentage,
    address _taxCollector
  )
    public
    isInitializer("HarbergerTaxable", "0.1.0")
  {
    HarbergerTaxable.initialize(_taxPercentage, _taxCollector);
    taxPercentage = _taxPercentage;
    taxCollector = _taxCollector;
  }

  function addToValueHeld(address user, uint256 value) public {
    _addToValueHeld(user, value);
  }

  function subFromValueHeld(address user, uint256 value, bool isInAuction) public {
    _subFromValueHeld(user, value, isInAuction);
  }

  function safeTransferTaxes(address user) public {
    require(transferTaxes(user, false));
  }

  function taxesDue(address user) public view returns (uint256) {
    return _taxesDue(user);
  }

}
