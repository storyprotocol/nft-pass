## Install libraries 
```npm install``` 

## Compile Smart Contract
```npx hardhat compile```

## Setup Environment
Provide a `.env` file under project root directory
```
GOERLI_URL = <Goerli rpc url e.g. https://rpc.ankr.com/eth_goerli>
PRIVATEKEY = <wallet private key used to sign transactions>
APIKEY = <ETHSCAN APIKEY>
```

## Deploy to Goerli

```npx hardhat run ./scripts/deploy.ts --network goerli```




