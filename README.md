# rari-tank-contracts
Tanks are a vault-like mechanism that supplies an asset on Fuse, borrows another one, and earns interest on it. Currently, Tanks will supply an asset to Fuse, borrow DAI, and deposit it into the Rari DAI Pool.

## Installation
Run `npm i` to install all necessary modules. Next, create an `.env` file, and set `BLOCK_NUMBER` (tested using 11911184) and `FORKING_URL` to your provider URL.

## Testing
Once setup, run `npx hardhat test --network hardhat`