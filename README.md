## Radical Pixels Contracts

### Run Tests

The first time you pull down the repo run `chmod +x scripts/**`.

```
npm test
```

### Deploy to Kovan

If you haven't already, create an account for the Kovan testnet:

```
$ parity account new --chain kovan
```

Add your account password to `/password_kovan.txt`

To start your Kovan node run:

```
$ parity --chain=kovan --unlock=YOUR_OWNER_ADDRESS --password=./password_kovan.txt --jsonrpc-apis web3,eth,net,personal,parity,parity_set,traces,rpc,parity_accounts
```

In `config/config.json` set `ownerAccount:` to your unlocked account.

### Main Net

If you haven't already, create an account to use with Parity on Main Net:

```
$ parity account new
```

Add your account password to `/password_mainnet.txt`

To start your node run:

```
$ parity --unlock=YOUR_OWNER_ADDRESS --password=./password_mainnet.txt --jsonrpc-apis web3,eth,net,personal,parity,parity_set,traces,rpc,parity_accounts
```

In `config/config.json` set `ownerAccount:` to your unlocked account.

### Deploy Contracts

If deploying to Kovan or Main Net make sure the deploying account has enough ETH for transaction fees.

Run:
```
$ yarn deploy-<development|kovan|mainnet>
```
