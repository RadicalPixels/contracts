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
    uint256 price
  );

  event SetPixelPrice(
    bytes32 indexed id,
    address indexed seller,
    uint256 x,
    uint256 y,
    uint256 price
  );

  event AddFunds(
    address indexed owner,
    uint256 indexed addedFunds
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

  constructor(uint256 _xMax, uint256 _yMax)
    public
  {
    require(_xMax > 0, "xMax must be a valid number");
    require(_yMax > 0, "yMax must be a valid number");

    xMax = _xMax;
    yMax = _yMax;
  }

  /**
   * Public Functions
   */

  /**
  * @dev Buys pixel blocks
  * @param _x X coordinates of the desired blocks
  * @param _y Y coordinates of the desired blocks
  * @param _price New prices of the pixel blocks
  */
  function buyUninitializedPixelBlocks(uint256[] _x, uint256[] _y, uint256[] _price)
    public
    payable
  {
    require(_x.length == _y.length && _x.length == _price.length);
    for (uint i = 0; i < _x.length; i++) {
      require(_price[i] > 0);
      _buyUninitializedPixelBlock(_x[i], _y[i], _price[i]);
    }
  }

  /**
  * @dev Buys pixel blocks
  * @param _x X coordinates of the desired blocks
  * @param _y Y coordinates of the desired blocks
  * @param _price New prices of the pixel blocks
  */
  function buyPixelBlocks(uint256[] _x, uint256[] _y, uint256[] _price)
    public
    payable
  {
    require(_x.length == _y.length && _x.length == _price.length);
    for (uint i = 0; i < _x.length; i++) {
      require(_price[i] > 0);
      _buyPixelBlock(_x[i], _y[i], _price[i]);
    }
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
   * @dev Adds funds to a users value held
   */
  function addFunds()
    public
    payable
  {
    _addToValueHeld(msg.sender, msg.value);
    emit AddFunds(msg.sender, msg.value);
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
    require(auction.endTime < block.timestamp);

    auction.currentPrice = _bid;
    auction.currentLeader = msg.sender;

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
    require(block.timestamp < auction.endTime);

    // End dutch auction
    address winner = _endDutchAuction(_x, _y);

    uint256 tokenId = _encodeTokenId(_x, _y);

    emit EndDutchAuction(
      pixel.id,
      tokenId,
      winner,
      _x,
      _y
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
  */
  function _buyUninitializedPixelBlock(uint256 _x, uint256 _y, uint256 _price)
    internal
    validRange(_x, _y)
    hasPositveBalance(msg.sender)
  {
    Pixel memory pixel = pixelByCoordinate[_x][_y];

    require(pixel.seller == address(0), "Pixel must not be initialized");

    uint256 tokenId = _encodeTokenId(_x, _y);
    bytes32 pixelId = _updatePixelMapping(msg.sender, _x, _y, _price);

    _mint(msg.sender, tokenId);

    emit BuyPixel(
      pixelId,
      address(0),
      msg.sender,
      _x,
      _y,
      _price
    );
  }

  /**
   * @dev Buys a pixel block
   * @param _x X coordinate of the desired block
   * @param _y Y coordinate of the desired block
   * @param _price New price of the pixel block
   */
  function _buyPixelBlock(uint256 _x, uint256 _y, uint256 _price)
    internal
    validRange(_x, _y)
    hasPositveBalance(msg.sender)
  {
    Pixel memory pixel = pixelByCoordinate[_x][_y];

    require(pixel.seller != address(0), "Pixel must be initialized");
    require(pixel.price == _price, "Must have sent sufficient funds");

    uint256 tokenId = _encodeTokenId(_x, _y);

    removeTokenFrom(pixel.seller, tokenId);
    addTokenTo(msg.sender, tokenId);

    emit Transfer(pixel.seller, msg.sender, tokenId);

    pixel.seller.transfer(pixel.price);

    emit BuyPixel(
      pixel.id,
      pixel.seller,
      msg.sender,
      _x,
      _y,
      pixel.price
    );
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

    delete pixelByCoordinate[_x][_y];

    bytes32 pixelId = _updatePixelMapping(msg.sender, _x, _y, _price);

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
    */
  function _updatePixelMapping
  (
    address _seller,
    uint256 _x,
    uint256 _y,
    uint256 _price
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
      x: _y,
      y: _x,
      price: _price,
      auctionId: 0
    });

    return pixelId;
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
