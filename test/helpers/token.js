const tokens = [
  {
    underlying: "0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599",
    decimals: 8,
    symbol: "WBTC",
    user: "0x56178a0d5f301baf6cf3e1cd53d9863437345bf9",
    depositAmount: "100000000",
    withdrawAmount: "50000000",
  },
  {
    underlying: "0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984",
    decimals: 18,
    symbol: "UNI",
    user: "0x0eb1afd80aec9e991c5f8d95a421be187974912f",
    depositAmount: "1000000000000000000000",
    withdrawAmount: "500000000000000000000",
  },
  {
    underlying: "0xE41d2489571d322189246DaFA5ebDe1F4699F498",
    decimals: 18,
    symbol: "ZRX",
    user: "0x85b5022bc07b21d69a0c3656ad74286e137cf5dd",
    depositAmount: "2000000000000000000000",
    withdrawAmount: "100000000000000000000",
  },
];
module.exports = {
  token: tokens[Math.floor(Math.random() * tokens.length)],
  borrowing: "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48",
  rspt: "0x016bf078ABcaCB987f0589a6d3BEAdD4316922B0",
  usdcHolder: "0x0f4ee9631f4be0a63756515141281a3e2b293bbe",
};
