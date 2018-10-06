pragma solidity ^0.4.24;

import 'zeppelin-solidity/contracts/math/SafeMath.sol';

/**
 * @title RadicalPixels
 */
contract RadicalPixels {
  using SafeMath for uint256;

  struct Pixel {
    // Owner of the pixel block
    address seller;
    // Pixel block x coordinate
    uint256 x;
    // Pixel block y coordinate
    uint256 y;
    // Pixel block price
    uint256 price;
  }

  mapping (uint256 => mapping(uint256 => Order)) public pixelByCoordinate;

  uint256 public xMax;
  uint256 public yMax;

  mapping(uint256 => mapping(uint256 => uint256)) public pixelBlockPrice;

  event BuyPixel(
    address indexed seller,
    address indexed buyer,
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
  * @dev Buys a pixel block
  * @param _x X coordinate of the desired block
  * @param _y Y coordinate of the desired block
  */
  funciton buyPixelBlock(uint256 _x, uint256 _y)
    public
    payable
    // userHasPositiveBalance
  {
    require(_x < xMax, "X coordinate is out of range");
    require(_y < yMax, "Y coordinate is out of range");

    Pixel memory pixel = pixelByCoordinate[_x][_y];

    require(pixel.seller != address(0), "Pixel must be initialized");
    require(pixel.price == msg.value, "Must have sent sufficient funds");

    // _removeTokenFrom(from, tokenId);
    // _addTokenTo(to, tokenId);
    //
    // emit Transfer(from, to, tokenId);


    pixel.seller.transfer(pixel.price);

    emit BuyPixel(
      seller,
      buyer,
      x,
      y,
      price
    );
  }

  // function buyUninitializedPixelBlock()

  // function sellPixelBlock public ()
  //   public
  //   payable
  // {
  //   emit BuyPixel(
  //     seller,
  //     buyer,
  //     x,
  //     y,
  //     price
  //   );
  // }


}
