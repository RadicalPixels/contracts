pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/token/ERC721/ERC721Token.sol";
import "./HarbergerTaxable.sol";

/**
 * @title RadicalPixels
 */
contract RadicalPixels is HarbergerTaxable, ERC721Token {
  using SafeMath for uint256;

  uint256 public   xMax;
  uint256 public   yMax;
  uint256 constant clearLow = 0xffffffffffffffffffffffffffffffff00000000000000000000000000000000;
  uint256 constant clearHigh = 0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff;
  uint256 constant factor = 0x100000000000000000000000000000000;

  struct Pixel {
    // Id of the pixel block
    bytes32 id;
    // Owner of the pixel block
    address seller;
    // Pixel block x coordinate
    uint256 x;
    // Pixel block y coordinate
    uint256 y;
    // Pixel block price
    uint256 price;
    // Auction Id
    bytes32 auctionId;
    // Content data
    bytes32 contentData;
  }

  struct Auction {
    // Id of the auction
    bytes32 auctionId;
    // Id of the pixel block
    bytes32 blockId;
    // Pixel block x coordinate
    uint256 x;
    // Pixel block y coordinate
    uint256 y;
    // Current price
    uint256 currentPrice;
    // Current Leader
    address currentLeader;
    // End Time
    uint256 endTime;
  }

  mapping(uint256 => mapping(uint256 => Pixel)) public pixelByCoordinate;
  mapping(bytes32 => Auction) public auctionById;

  /**
   * Modifiers
   */
   modifier validRange(uint256 _x, uint256 _y)
  {
    require(_x < xMax, "X coordinate is out of range");
    require(_y < yMax, "Y coordinate is out of range");
    _;
  }

  /**
   * Events
   */

  event BuyPixel(
    bytes32 indexed id,
    address indexed seller,
    address indexed buyer,
    uint256 x,
    uint256 y,
    uint256 price,
    bytes32 contentData
  );

  event SetPixelPrice(
    bytes32 indexed id,
    address indexed seller,
    uint256 x,
    uint256 y,
    uint256 price
  );

  event BeginDutchAuction(
    bytes32 indexed pixelId,
    uint256 indexed tokenId,
    bytes32 indexed auctionId,
    address initiator,
    uint256 x,
    uint256 y,
    uint256 startTime,
    uint256 endTime
  );

  event UpdateAuctionBid(
    bytes32 indexed pixelId,
    uint256 indexed tokenId,
    bytes32 indexed auctionId,
    address bidder,
    uint256 amountBet,
    uint256 timeBet
  );

  event EndDutchAuction(
    bytes32 indexed pixelId,
    uint256 indexed tokenId,
    address indexed claimer,
    uint256 x,
    uint256 y
  );

  event UpdateContentData(
    bytes32 indexed pixelId,
    address indexed owner,
    uint256 x,
    uint256 y,
    bytes32 newContentData
  );

  constructor(uint256 _xMax, uint256 _yMax, uint256 _taxPercentage, address _taxCollector)
    public
    ERC721Token("Radical Pixels", "RPX")
    HarbergerTaxable(_taxPercentage, _taxCollector)
  {
    require(_xMax > 0, "xMax must be a valid number");
    require(_yMax > 0, "yMax must be a valid number");

    xMax = _xMax;
    yMax = _yMax;
  }

  /**
   * Public Functions
   */


  function transferFrom(address _from, address _to, uint256 _tokenId, uint256 _price)
    public
  {
    _subFromValueHeld(msg.sender, _price);
    _addToValueHeld(_to, _price);
    require(_to == msg.sender);

    super.transferFrom(_from, _to, _tokenId);
  }

   /**
   * @dev Buys pixel block
   * @param _x X coordinate of the desired block
   * @param _y Y coordinate of the desired block
   * @param _price New price of the pixel block
   * @param _contentData Data for the pixel
   */
   function buyUninitializedPixelBlock(uint256 _x, uint256 _y, uint256 _price, bytes32 _contentData)
     public
   {
     require(_price > 0);
     _buyUninitializedPixelBlock(_x, _y, _price, _contentData);
   }

  /**
  * @dev Buys pixel blocks
  * @param _x X coordinates of the desired blocks
  * @param _y Y coordinates of the desired blocks
  * @param _price New prices of the pixel blocks
  * @param _contentData Data for the pixel
  */
  function buyUninitializedPixelBlocks(uint256[] _x, uint256[] _y, uint256[] _price, bytes32[] _contentData)
    public
  {
    require(_x.length == _y.length && _x.length == _price.length && _x.length == _contentData.length);
    for (uint i = 0; i < _x.length; i++) {
      require(_price[i] > 0);
      _buyUninitializedPixelBlock(_x[i], _y[i], _price[i], _contentData[i]);
    }
  }

  /**
  * @dev Buys pixel block
  * @param _x X coordinate of the desired block
  * @param _y Y coordinate of the desired block
  * @param _price New price of the pixel block
  * @param _contentData Data for the pixel
  */
  function buyPixelBlock(uint256 _x, uint256 _y, uint256 _price, bytes32 _contentData)
    public
    payable
  {
    require(_price > 0);
    uint256 _ = _buyPixelBlock(_x, _y, _price, msg.value, _contentData);
  }

  /**
  * @dev Buys pixel block
  * @param _x X coordinates of the desired blocks
  * @param _y Y coordinates of the desired blocks
  * @param _price New prices of the pixel blocks
  * @param _contentData Data for the pixel
  */
  function buyPixelBlocks(uint256[] _x, uint256[] _y, uint256[] _price, bytes32[] _contentData)
    public
    payable
  {
    require(_x.length == _y.length && _x.length == _price.length && _x.length == _contentData.length);
    uint256 currentValue = msg.value;
    for (uint i = 0; i < _x.length; i++) {
      require(_price[i] > 0);
      currentValue = _buyPixelBlock(_x[i], _y[i], _price[i], currentValue, _contentData[i]);
    }
  }

  /**
  * @dev Set prices for specific blocks
  * @param _x X coordinate of the desired block
  * @param _y Y coordinate of the desired block
  * @param _price New price of the pixel block
  */
  function setPixelBlockPrice(uint256 _x, uint256 _y, uint256 _price)
    public
    payable
  {
    require(_price > 0);
    _setPixelBlockPrice(_x, _y, _price);
  }

  /**
  * @dev Set prices for specific blocks
  * @param _x X coordinates of the desired blocks
  * @param _y Y coordinates of the desired blocks
  * @param _price New prices of the pixel blocks
  */
  function setPixelBlockPrices(uint256[] _x, uint256[] _y, uint256[] _price)
    public
    payable
  {
    require(_x.length == _y.length && _x.length == _price.length);
    for (uint i = 0; i < _x.length; i++) {
      require(_price[i] > 0);
      _setPixelBlockPrice(_x[i], _y[i], _price[i]);
    }
  }

  /**
   * Trigger a dutch auction
   * @param _x X coordinate of the desired block
   * @param _y Y coordinate of the desired block
   */
  function beginDutchAuction(uint256 _x, uint256 _y)
    public
    validRange(_x, _y)
  {
    Pixel memory pixel = pixelByCoordinate[_x][_y];

    require(!userHasPositveBalance(pixel.seller));
    require(pixel.auctionId == 0);

    // Start a dutch auction
    pixel.auctionId = _generateDutchAuction(_x, _y);
    uint256 tokenId = _encodeTokenId(_x, _y);

    _updatePixelMapping(pixel.seller, _x, _y, pixel.price, pixel.auctionId, "");

    emit BeginDutchAuction(
      pixel.id,
      tokenId,
      pixel.auctionId,
      msg.sender,
      _x,
      _y,
      block.timestamp,
      block.timestamp.add(1 days)
    );
  }

  /**
   * @dev Allow a user to bid in an auction
   * @param _x X coordinate of the desired block
   * @param _y Y coordinate of the desired block
   * @param _bid Desired bid of the user
   */
  function bidInAuction(uint256 _x, uint256 _y, uint256 _bid)
    public
    validRange(_x, _y)
  {
    Pixel memory pixel = pixelByCoordinate[_x][_y];
    Auction memory auction = auctionById[pixel.auctionId];

    uint256 _tokenId = _encodeTokenId(_x, _y);
    require(pixel.auctionId != 0);
    require(auction.currentPrice < _bid);
    require(block.timestamp < auction.endTime);

    auction.currentPrice = _bid;
    auction.currentLeader = msg.sender;

    // _subFromValueHeld(msg.sender, priceTheyWerePaying);
    // _addToValueHeld(_to, newPrice*tax*freq )

    emit UpdateAuctionBid(
      pixel.id,
      _tokenId,
      auction.auctionId,
      msg.sender,
      _bid,
      block.timestamp
    );
  }

  /**
   * End the auction
   * @param _x X coordinate of the desired block
   * @param _y Y coordinate of the desired block
   */
  function endDutchAuction(uint256 _x, uint256 _y)
    public
    validRange(_x, _y)
  {
    Pixel memory pixel = pixelByCoordinate[_x][_y];
    Auction memory auction = auctionById[pixel.auctionId];

    require(pixel.auctionId != 0);
    require(auction.endTime < block.timestamp);

    // End dutch auction
    address winner = _endDutchAuction(_x, _y);
    _updatePixelMapping(winner, _x, _y, auction.currentPrice, 0, "");

    uint256 tokenId = _encodeTokenId(_x, _y);
    removeTokenFrom(pixel.seller, tokenId);
    addTokenTo(winner, tokenId);
    emit Transfer(pixel.seller, winner, tokenId);

    emit EndDutchAuction(
      pixel.id,
      tokenId,
      winner,
      _x,
      _y
    );
  }

  /**
  * @dev Change content data of a pixel
  * @param _x X coordinates of the desired blocks
  * @param _y Y coordinates of the desired blocks
  * @param _contentData Data for the pixel
  */
  function changeContentData(uint256 _x, uint256 _y, bytes32 _contentData)
    public
  {
    Pixel memory pixel = pixelByCoordinate[_x][_y];

    require(msg.sender == pixel.seller);

    pixel.contentData = _contentData;

    emit UpdateContentData(
      pixel.id,
      pixel.seller,
      _x,
      _y,
      _contentData
  );

  }

  /**
   * Encode a token ID for transferability
   * @param _x X coordinate of the desired block
   * @param _y Y coordinate of the desired block
   */
  function encodeTokenId(uint256 _x, uint256 _y)
    public
    view
    validRange(_x, _y)
    returns (uint256)
  {
    return _encodeTokenId(_x, _y);
  }

  /**
   * Internal Functions
   */

  /**
  * @dev Buys an uninitialized pixel block for 0 ETH
  * @param _x X coordinate of the desired block
  * @param _y Y coordinate of the desired block
  * @param _price New price for the pixel
  * @param _contentData Data for the pixel
  */
  function _buyUninitializedPixelBlock(uint256 _x, uint256 _y, uint256 _price, bytes32 _contentData)
    internal
    validRange(_x, _y)
    hasPositveBalance(msg.sender)
  {
    Pixel memory pixel = pixelByCoordinate[_x][_y];

    require(pixel.seller == address(0), "Pixel must not be initialized");

    uint256 tokenId = _encodeTokenId(_x, _y);
    bytes32 pixelId = _updatePixelMapping(msg.sender, _x, _y, _price, 0, _contentData);

    _addToValueHeld(msg.sender, _price);
    _mint(msg.sender, tokenId);

    emit BuyPixel(
      pixelId,
      address(0),
      msg.sender,
      _x,
      _y,
      _price,
      _contentData
    );
  }

  /**
   * @dev Buys a pixel block
   * @param _x X coordinate of the desired block
   * @param _y Y coordinate of the desired block
   * @param _price New price of the pixel block
   * @param _currentValue Current value of the transaction
   * @param _contentData Data for the pixel
   */
  function _buyPixelBlock(uint256 _x, uint256 _y, uint256 _price, uint256 _currentValue, bytes32 _contentData)
    internal
    validRange(_x, _y)
    hasPositveBalance(msg.sender)
    returns (uint256)
  {
    Pixel memory pixel = pixelByCoordinate[_x][_y];
    uint256 _taxOnPrice = _calculateTax(_price);

    require(pixel.seller != address(0), "Pixel must be initialized");
    require(userBalanceAtLastPaid[msg.sender] >= _taxOnPrice);
    require(pixel.price <= _currentValue, "Must have sent sufficient funds");

    uint256 tokenId = _encodeTokenId(_x, _y);

    removeTokenFrom(pixel.seller, tokenId);
    addTokenTo(msg.sender, tokenId);
    emit Transfer(pixel.seller, msg.sender, tokenId);

    _addToValueHeld(msg.sender, _price);
    _subFromValueHeld(pixel.seller, _price);

    _updatePixelMapping(msg.sender, _x, _y, _price, 0, _contentData);
    pixel.seller.transfer(pixel.price);

    emit BuyPixel(
      pixel.id,
      pixel.seller,
      msg.sender,
      _x,
      _y,
      pixel.price,
      _contentData
    );

    return _currentValue.sub(pixel.price);
  }

  /**
  * @dev Set prices for a specific block
  * @param _x X coordinate of the desired block
  * @param _y Y coordinate of the desired block
  * @param _price New price of the pixel block
  */
  function _setPixelBlockPrice(uint256 _x, uint256 _y, uint256 _price)
    internal
    validRange(_x, _y)
  {
    Pixel memory pixel = pixelByCoordinate[_x][_y];

    require(pixel.seller == msg.sender, "Sender must own the block");
    _addToValueHeld(msg.sender, _price);

    delete pixelByCoordinate[_x][_y];

    bytes32 pixelId = _updatePixelMapping(msg.sender, _x, _y, _price, 0, "");

    emit SetPixelPrice(
      pixelId,
      pixel.seller,
      _x,
      _y,
      pixel.price
    );
  }

  /**
   * Generate a dutch auction
   * @param _x X coordinate of the desired block
   * @param _y Y coordinate of the desired block
   */
  function _generateDutchAuction(uint256 _x, uint256 _y)
    internal
    returns (bytes32)
  {
    Pixel memory pixel = pixelByCoordinate[_x][_y];

    bytes32 _auctionId = keccak256(
      abi.encodePacked(
        block.timestamp,
        _x,
        _y
      )
    );

    auctionById[_auctionId] = Auction({
      auctionId: _auctionId,
      blockId: pixel.id,
      x: _x,
      y: _y,
      currentPrice: 0,
      currentLeader: msg.sender,
      endTime: block.timestamp.add(1 days)
    });

    return _auctionId;
  }

  /**
   * End a finished dutch auction
   * @param _x X coordinate of the desired block
   * @param _y Y coordinate of the desired block
   */
  function _endDutchAuction(uint256 _x, uint256 _y)
    internal
    returns (address)
  {
    Pixel memory pixel = pixelByCoordinate[_x][_y];
    Auction memory auction = auctionById[pixel.auctionId];

    address _winner = auction.currentLeader;

    delete auctionById[auction.auctionId];

    return _winner;
  }
  /**
    * @dev Update pixel mapping every time it is purchase or the price is
    * changed
    * @param _seller Seller of the pixel block
    * @param _x X coordinate of the desired block
    * @param _y Y coordinate of the desired block
    * @param _price Price of the pixel block
    * @param _contentData Data for the pixel
    */
  function _updatePixelMapping
  (
    address _seller,
    uint256 _x,
    uint256 _y,
    uint256 _price,
    bytes32 _auctionId,
    bytes32 _contentData
  )
    internal
    returns (bytes32)
  {
    bytes32 pixelId = keccak256(
      abi.encodePacked(
        _x,
        _y
      )
    );

    pixelByCoordinate[_x][_y] = Pixel({
      id: pixelId,
      seller: _seller,
      x: _x,
      y: _y,
      price: _price,
      auctionId: _auctionId,
      contentData: _contentData
    });

    return pixelId;
  }

  function _calculateTax(uint256 _price)
    internal
    view
    returns (uint256)
  {
    return _price.mul(taxPercentage).div(100);
  }
  /**
   * Encode token ID
   * @param _x X coordinate of the desired block
   * @param _y Y coordinate of the desired block
   */
  function _encodeTokenId(uint256 _x, uint256 _y)
    internal
    pure
    returns (uint256 result)
  {
    return ((_x * factor) & clearLow) | (_y & clearHigh);
  }
}
