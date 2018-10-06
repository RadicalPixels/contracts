
const BigNumber = web3.BigNumber;

require('chai')
  .use(require('chai-bignumber')(BigNumber))
  .should();

const HarbingerTaxable = artifacts.require('HarbingerTaxableMock');

contract('HarbingerTaxable', function (accounts) {
  
})
