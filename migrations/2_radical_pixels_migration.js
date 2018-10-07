var RadicalPixels = artifacts.require("./RadicalPixels.sol");

module.exports = function(deployer) {
  deployer.deploy(RadicalPixels, 1000, 1000, 20, "0x60ea769c3b7b9c91bcf8d9c573db58f06e4efe12")
};
