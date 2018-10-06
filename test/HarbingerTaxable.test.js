
const BigNumber = web3.BigNumber;

require('chai')
  .use(require('chai-bignumber')(BigNumber))
  .should();

const HarbergerTaxable = artifacts.require('HarbergerTaxableMock');

contract('HarbergerTaxable', function (accounts) {
  
})
