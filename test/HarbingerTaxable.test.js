const { latestTime } = require('./helpers/latestTime');
const { increaseTimeTo, duration } = require('./helpers/increaseTime');

const BigNumber = web3.BigNumber;

require('chai')
  .use(require('chai-bignumber')(BigNumber))
  .should();

const HarbergerTaxableMock = artifacts.require('HarbergerTaxableMock');

contract('HarbergerTaxable', ([_, taxCollector, act1, act2]) => {

  it('should collect taxes', async () => {
    let taxCollectorOriginalBal = await web3.eth.getBalance(taxCollector)
    let harbergerTaxable = await HarbergerTaxableMock.new(20, taxCollector)
    let releaseTime = await latestTime()

    await web3.eth.sendTransaction({from: act1, to: harbergerTaxable.address, value: web3.toWei(1)})
    await web3.eth.sendTransaction({from: act2, to: harbergerTaxable.address, value: web3.toWei(1)})

    await harbergerTaxable.addToValueHeld(act1, web3.toWei(1))
    await harbergerTaxable.addToValueHeld(act2, web3.toWei(2))

    await increaseTimeTo(releaseTime + duration.years(1));

    await harbergerTaxable.safeTransferTaxes(act1)
    await harbergerTaxable.safeTransferTaxes(act2)

    let taxCollectorBal = web3.fromWei(await web3.eth.getBalance(taxCollector))
    let taxCollectorExpectedBal = web3.fromWei(taxCollectorOriginalBal).add(0.6)
    taxCollectorBal.should.be.bignumber.equal(taxCollectorExpectedBal, 5)
  })

})
