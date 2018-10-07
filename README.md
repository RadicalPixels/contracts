## Radical Pixels Contracts

### Run Tests

The first time you pull down the repo run `chmod +x scripts/**`.

```
npm test
```
##### Deploy to Kovan:

If you haven't already, create an account for the Kovan testnet (The output will be your `ownerAddress`):

```
$ parity account new --chain kovan
```

Add your account password to `/password_kovan.txt`

To start your Kovan node run:

```
$ parity --chain=kovan --unlock=YOUR_OWNER_ADDRESS --password=./password_kovan.txt --jsonrpc-apis web3,eth,net,personal,parity,parity_set,traces,rpc,parity_accounts
```

In `config/config.json` set `ownerAccount:` to your unlocked Kovan account and set `network:` to `kovan`.
