const { latestTime } = require('./helpers/latestTime');
const { increaseTimeTo, duration } = require('./helpers/increaseTime');

const BigNumber = web3.BigNumber;

require('chai')
  .use(require('chai-bignumber')(BigNumber))
  .should();

const HarbergerTaxableMock = artifacts.require('HarbergerTaxableMock');
const RadicalPixels = artifacts.require('RadicalPixels');

contract('HarbergerTaxable', ([_, taxCollector, act1, act2, act3, act4]) => {

  const xMax = 1000;
  const yMax = 1000;
  const contentValue = "0x000000"

  describe.only('Auction', async () => {
    it('should initialize a pixel and add funds', async () => {
      let radicalPixels = await RadicalPixels.new(xMax, yMax, 20, taxCollector);
      await radicalPixels.addFunds({from: act1, value: web3.toWei(5, 'ether')});
      await radicalPixels.addFunds({from: act2, value: web3.toWei(5, 'ether')});

      await radicalPixels.buyUninitializedPixelBlock(0, 0, web3.toWei(1, 'ether'), contentValue, {from: act1});

      var pixelData = await radicalPixels.pixelByCoordinate(0, 0);
      assert.equal(pixelData[1], act1, "Pixel did not get transfered")

      let act1ValueHeld = await radicalPixels.valueHeld(act1);
      let act1ExpectedValueHeld = new BigNumber(1e18);
      assert.equal(act1ValueHeld.toNumber(), act1ExpectedValueHeld.toNumber(), "Did not transfer funds")
    })
    it('should allow someone to buy the pixel from the original purhcaser', async () => {
      let radicalPixels = await RadicalPixels.new(xMax, yMax, 20, taxCollector);
      await radicalPixels.addFunds({from: act1, value: web3.toWei(5, 'ether')});
      await radicalPixels.addFunds({from: act2, value: web3.toWei(5, 'ether')});

      await radicalPixels.buyUninitializedPixelBlock(0, 0, web3.toWei(1, 'ether'), contentValue, {from: act1});

      var pixelData = await radicalPixels.pixelByCoordinate(0, 0);
      assert.equal(pixelData[1], act1, "Pixel did not get transfered")

      let act1ValueHeld = await radicalPixels.valueHeld(act1);
      let act1ExpectedValueHeld = new BigNumber(1e18);
      assert.equal(act1ValueHeld.toNumber(), act1ExpectedValueHeld.toNumber(), "Did not transfer funds")

      await radicalPixels.buyPixelBlock(0, 0, web3.toWei(2, 'ether'), contentValue, {from: act2, value: web3.toWei(1, 'ether')});

      var pixelData = await radicalPixels.pixelByCoordinate(0, 0);
      assert.equal(pixelData[1], act2, "Pixel did not get transfered")
    })

    it('should not allow someone to buy the pixel if they don\'t send enough funds', async () => {
      let radicalPixels = await RadicalPixels.new(xMax, yMax, 20, taxCollector);
      await radicalPixels.addFunds({from: act1, value: web3.toWei(5, 'ether')});
      await radicalPixels.addFunds({from: act2, value: web3.toWei(5, 'ether')});

      await radicalPixels.buyUninitializedPixelBlock(0, 0, web3.toWei(1, 'ether'), contentValue, {from: act1});
      var pixelData = await radicalPixels.pixelByCoordinate(0, 0);
      assert.equal(pixelData[1], act1, "Pixel did not get transfered")


      let act1ValueHeld = await radicalPixels.valueHeld(act1);
      let act1ExpectedValueHeld = new BigNumber(1e18);
      assert.equal(act1ValueHeld.toNumber(), act1ExpectedValueHeld.toNumber(), "Did not transfer funds")

      try {
        await radicalPixels.buyPixelBlocks([0], [0], [web3.toWei(2, 'ether')], {from: act2, value: web3.toWei(0.5, 'ether')});
      } catch (e) {
        return true;
      }
      assert.fail("Transaction should not have gone through");
    })

    it('should set a new pixel price', async () => {
      let radicalPixels = await RadicalPixels.new(xMax, yMax, 20, taxCollector);
      await radicalPixels.addFunds({from: act1, value: web3.toWei(5, 'ether')});
      await radicalPixels.addFunds({from: act2, value: web3.toWei(5, 'ether')});

      await radicalPixels.buyUninitializedPixelBlock(0, 0, web3.toWei(1, 'ether'), contentValue, {from: act1});
      var pixelData = await radicalPixels.pixelByCoordinate(0, 0);
      assert.equal(pixelData[1], act1, "Pixel did not get transfered")

      await radicalPixels.setPixelBlockPrices([0], [0], [web3.toWei(0.5, 'ether')], {from: act1});
      var pixelData = await radicalPixels.pixelByCoordinate(0, 0);

      let expectedPrice = new BigNumber(0.5e18);
      assert.equal(pixelData[4].toNumber(), expectedPrice.toNumber(), "Value to not change")
    })

    it('should create an auction', async () => {
      let radicalPixels = await RadicalPixels.new(xMax, yMax, 20, taxCollector);
      await radicalPixels.addFunds({from: act1, value: web3.toWei(5, 'ether')});
      await radicalPixels.addFunds({from: act2, value: web3.toWei(5, 'ether')});
      let releaseTime = await latestTime()

      await radicalPixels.buyUninitializedPixelBlock(0, 0, web3.toWei(1, 'ether'), contentValue, {from: act1});
      var pixelData = await radicalPixels.pixelByCoordinate(0, 0);
      assert.equal(pixelData[1], act1, "Pixel did not get transfered")

      await increaseTimeTo(releaseTime + duration.years(100));

      let auctionId = await radicalPixels.encodeTokenId(0, 0);
      await radicalPixels.beginDutchAuction(0, 0)

      let auctionData = await radicalPixels.pixelByCoordinate(0, 0);
      assert.notEqual(0,auctionData[5],'Auction did not get created');
    })

    it('should complete an auction after someone else bets', async () => {
      let radicalPixels = await RadicalPixels.new(xMax, yMax, 20, taxCollector);
      await radicalPixels.addFunds({from: act1, value: web3.toWei(5, 'ether')});
      await radicalPixels.addFunds({from: act2, value: web3.toWei(5, 'ether')});
      await radicalPixels.addFunds({from: act3, value: web3.toWei(5, 'ether')});

      let releaseTime = await latestTime()

      await radicalPixels.buyUninitializedPixelBlock(0, 0, web3.toWei(1, 'ether'), contentValue, {from: act1});
      let pixelData = await radicalPixels.pixelByCoordinate(0, 0);
      assert.equal(pixelData[1], act1, "Pixel did not get transfered")

      await increaseTimeTo(releaseTime + duration.years(100));
      releaseTime = await latestTime()

      let auctionId = await radicalPixels.encodeTokenId(0, 0);
      await radicalPixels.beginDutchAuction(0, 0)

      let auctionData = await radicalPixels.pixelByCoordinate(0, 0);
      assert.notEqual(0,auctionData[5],'lol');

      await radicalPixels.bidInAuction(0, 0, web3.toWei(1, 'ether'), {from: act2});
      await radicalPixels.bidInAuction(0, 0, web3.toWei(2, 'ether'), {from: act3});

      await increaseTimeTo(releaseTime + duration.days(2));

      await radicalPixels.endDutchAuction(0, 0);
    })

    it('should not allow someone to add a lower value to the auction', async () => {
      let radicalPixels = await RadicalPixels.new(xMax, yMax, 20, taxCollector);
      await radicalPixels.addFunds({from: act1, value: web3.toWei(5, 'ether')});
      await radicalPixels.addFunds({from: act2, value: web3.toWei(5, 'ether')});
      await radicalPixels.addFunds({from: act3, value: web3.toWei(5, 'ether')});

      let releaseTime = await latestTime()

      await radicalPixels.buyUninitializedPixelBlock(0, 0, web3.toWei(1, 'ether'), contentValue, {from: act1});
      let pixelData = await radicalPixels.pixelByCoordinate(0, 0);
      assert.equal(pixelData[1], act1, "Pixel did not get transfered")

      await increaseTimeTo(releaseTime + duration.years(100));

      let auctionId = await radicalPixels.encodeTokenId(0, 0);
      await radicalPixels.beginDutchAuction(0, 0)

      let auctionData = await radicalPixels.pixelByCoordinate(0, 0);
      assert.notEqual(0,auctionData[5],'lol');

      await radicalPixels.bidInAuction(0, 0, web3.toWei(1, 'ether'), {from: act2});
      await radicalPixels.bidInAuction(0, 0, web3.toWei(2, 'ether'), {from: act3});
      try {
        await radicalPixels.bidInAuction(0, 0, web3.toWei(1, 'ether'), {from: act3});
      } catch (e) {
        return true;
      }
      assert.fail("User bid less than the previous value");
    })
  });
})
