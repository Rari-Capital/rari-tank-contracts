tokens = [
    {
        symbol: "WBTC",
        address: "0x2260fac5e5542a773aa44fbcfedf7c193bc2c599",
        holder: "0x0C4809bE72F9E117D75381438c5dAeC8AbE75BaD",
        depositAmount: "100000000",
        withdrawalAmount: "100000500",
        largeWithdrawalAmount: "200000500"
    },
    {
        symbol: "USDC",
        address: "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",
        holder: "0x55FE002aefF02F77364de339a1292923A15844B8",
        depositAmount: "50000000000",
        withdrawalAmount: "50500000000",
        largeWithdrawalAmount: "100000000000"
    },
    // {
    //     symbol: "UNI",
    //     address: "0x1f9840a85d5af5bf1d1762f925bdaddc4201f984",
    //     holder: "0xD5Ba96148DF85DFea6E35C515D3aCEf08db6C996",
    //     depositAmount: "1750000000000000000000",
    //     withdrawalAmount: "1775000000000000000000",
    //     largeWithdrawalAmount: "3550000000000000000000"
    // },
];

const token = tokens[Math.floor(Math.random() * tokens.length)];

module.exports = {
    TOKEN: token.address,
    TOKEN_SYMBOL: token.symbol,
    HOLDER: token.holder,
    AMOUNT: token.depositAmount,
    WITHDRAWAL_AMOUNT: token.withdrawalAmount,
    LARGE_WITHDRAWAL_AMOUNT: token.largeWithdrawalAmount,

    DAI: "0x6b175474e89094c44da98b954eedeac495271d0f",
    DAI_HOLDER: "0x01Ec5e7e03e2835bB2d1aE8D2edDEd298780129c",
    
    RSPT: "0x0833cfcb11A5ba89FbAF73a407831c98aD2D7648",
    RARI_FUND_CONTROLLER: "0xd7590e93a2e04110ad50ec70eade7490f7b8228a",
    
    FUSE_COMPTROLLER: "0x6E7fb6c5865e8533D5ED31b6d43fD95f4C411834",
    FUSE_POOL_DIRECTORY: "0x835482FE0532f169024d5E9410199369aAD5C77E",

    KEEP3R: "0x1cEB5cB57C4D4E2b2433641b95Dd330A33185A44",
    CHAINLINK_ORACLE: "0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419",
    KEEP3R_GOVERNANCE: "0x2d407ddb06311396fe14d4b49da5f0471447d45c",
    
    ORACLE_BOT: "0xadf76760f1d6b984e39c27c87d5f9661cefc5a21",
    KEEP3R_ORACLE: "0x73353801921417F465377c8d898c6f4C0270282C",

    FUSE_DEPLOYER: "0xf977814e90da44bfa03b6295a0616a897441acec",
    FUSE_DEPLOYER_SECONDARY: "0x1Eeb75CFad36EDb6C996f7809f30952B0CA0B5B9",
}