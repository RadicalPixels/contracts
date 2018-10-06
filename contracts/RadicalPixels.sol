pragma solidity ^0.4.24;

import 'zeppelin-solidity/contracts/math/SafeMath.sol';

/**
 * @title RadicalPixels
 */
contract RadicalPixels {
  using SafeMath for uint256;

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
  }

  mapping (uint256 => mapping(uint256 => Pixel)) public pixelByCoordinate;

  uint256 public xMax;
  uint256 public yMax;

  mapping(uint256 => mapping(uint256 => uint256)) public pixelBlockPrice;

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
  * @dev Buys an uninitialized pixel block for 0 ETH
  * @param _x X coordinate of the desired block
  * @param _y Y coordinate of the desired block
  * @param _price New price for the pixel
  */
  function buyUninitializedPixelBlock(uint256 _x, uint256 _y, uint256 _price)
    public
    payable
    validRange(_x, _y)
    // userHasPositiveBalance
  {
    Pixel memory pixel = pixelByCoordinate[_x][_y];

    require(pixel.seller == address(0), "Pixel must not be initialized");

    bytes32 pixelId = _updatePixelMapping(msg.sender, _x, _y, _price);

    // TODO: Mint token
    // _mint(to, tokenId)

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
    // _addToValueHeld(msg.sender, msg.value);
  }

  /**
   * Internal Functions
   */

   /**
   * @dev Buys a pixel block
   * @param _x X coordinate of the desired block
   * @param _y Y coordinate of the desired block
   * @param _price New price of the pixel block
   */
   function _buyPixelBlock(uint256 _x, uint256 _y, uint256 _price)
     internal
     validRange(_x, _y)
     // userHasPositiveBalance
   {
     Pixel memory pixel = pixelByCoordinate[_x][_y];

     require(pixel.seller != address(0), "Pixel must be initialized");
     require(pixel.price == _price, "Must have sent sufficient funds");

     // TODO: Send token
     // _removeTokenFrom(from, tokenId);
     // _addTokenTo(to, tokenId);
     //
     // emit Transfer(from, to, tokenId);

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
      price: _price
    });

    return pixelId;
  }
}
