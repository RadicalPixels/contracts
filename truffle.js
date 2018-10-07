
const config = require('./config.json')

module.exports = {
  // See <http://truffleframework.com/docs/advanced/configuration>
  // to customize your Truffle configuration!

  networks: {
    development: {
      host: 'localhost',
      port: 8545,
      network_id: '*', // eslint-disable-line camelcase
    },
    kovan: {
      host: 'localhost',
      port: 8545,
      network_id: '*', // Match any network id
      gas: 6000000,
      from: config.ownerAccount
    }
  }
};
