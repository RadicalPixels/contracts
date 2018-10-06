pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";

contract HarbingerTaxable {
  using SafeMath for uint256;

  uint256 public taxPercentage;
  address public taxCollector;

  constructor(uint256 _taxPercentage, address _taxCollector) public {
    taxPercentage = _taxPercentage;
    taxCollector = _taxCollector;
  }

  // The total self-assessed value of user's assets
  mapping(address => uint256) private valueHeld;

  // Timestamp for the last time taxes were deducted from a user's account
  mapping(address => uint256) private lastPaidTaxes;

  // The amount of ETH a user can withdraw at the last time taxes were deducted from their account
  mapping(address => uint256) private userBalanceAtLastPaid;

  /**
   * Modifiers
   */ 
  
  modifier hasPositveBalance(address user) {
    require(userHasPositveBalance(user) == true, "User has a negative balance");
    _;
  }

  /**
   * Public functions
   */
   
  function() public payable {
    userBalanceAtLastPaid[msg.sender] = userBalanceAtLastPaid[msg.sender] + msg.value;
  }

  function withdraw(uint256 value) public {
    // Settle latest taxes
    require(transferTaxes(msg.sender), "User has a negative balance");
    
    // Subtract the withdrawn value from the user's account
    userBalanceAtLastPaid[msg.sender] = userBalanceAtLastPaid[msg.sender] - value;
    
    // Transfer remaining balance to msg.sender
    msg.sender.transfer(value);
  }

  function userHasPositveBalance(address user) public view returns (bool) {
    return userBalanceAtLastPaid[user] >= _taxesDue(user);
  }
  
  function userBalance(address user) public view returns (uint256) {
    return userBalanceAtLastPaid[user] - _taxesDue(user);
  }
  
  // Transfers the taxes a user owes from their account to the taxCollector and resets lastPaidTaxes to now
  function transferTaxes(address user) public returns (bool) {

    uint256 taxesDue = _taxesDue(user);
    
    // Make sure the user has enough funds to pay the taxesDue
    if (userBalanceAtLastPaid[user] < taxesDue) {
        return false;
    }
    
    // Transfer taxes due from this contract to the tax collector
    taxCollector.transfer(taxesDue);
    // Update the user's lastPaidTaxes
    lastPaidTaxes[user] = now;
    // subtract the taxes paid from the user's balance
    userBalanceAtLastPaid[user] = userBalanceAtLastPaid[user] - taxesDue;
    
    return true;
  }

  /**
   * Internal functions
   */

  // Calculate taxes due since the last time they had taxes deducted
  // from their account or since they bought their first token.
  function _taxesDue(address user) internal view returns (uint256) {
    // Make sure user owns tokens
    require(lastPaidTaxes[user] != 0, "User does not own any tokens");

    uint256 timeElapsed = now - lastPaidTaxes[user];
    return (valueHeld[user] * timeElapsed / 1 days)  * taxPercentage / 100;
  }

  function _addToValueHeld(address user, uint256 value) internal {
    require(transferTaxes(user), "User has a negative balance");
    valueHeld[user] = valueHeld[user] + value;
  }

  function _subFromValueHeld(address user, uint256 value) internal {
    require(transferTaxes(user), "User has a negative balance");
    valueHeld[user] = valueHeld[user] + value;
  }
}
