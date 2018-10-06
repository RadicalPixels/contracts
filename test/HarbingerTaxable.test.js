
const BigNumber = web3.BigNumber;

require('chai')
  .use(require('chai-bignumber')(BigNumber))
  .should();

const HarbergerTaxableMock = artifacts.require('HarbergerTaxableMock');

contract('HarbergerTaxable', (accounts) => {

  it('should collect taxes', async () => {
    let harbergerTaxable = await HarbergerTaxableMock.new(20, accounts[0])
  })

})
