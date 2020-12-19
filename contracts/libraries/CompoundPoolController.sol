pragma solidity ^0.5.0;

/**
    @title CompoundFundController
    @author David Lucid <david@rari.capital>, Jet Jadeja (jet@rari.capital)
    @dev This library is used to handle interactions with Compound
*/
library CompoundFundController {
    function getCErc20Contract(address erc20Contract) private pure returns (address) {
        if (erc20Contract == 0x0D8775F648430679A709E98d2b0Cb6250d2887EF) return 0x6C8c6b02E7b2BE14d4fA6022Dfd6d75921D90E4E; // BAT => cBAT
        if (erc20Contract == 0xc00e94Cb662C3520282E6f5717214004A7f26888) return 0x70e36f6BF80a52b3B46b3aF8e106CC0ed743E8e4; // COMP => cCOMP
        if (erc20Contract == 0x6B175474E89094C44Da98b954EedeAC495271d0F) return 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643; // DAI => cDAI
        if (erc20Contract == 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984) return 0x35A18000230DA775CAc24873d00Ff85BccdeD550; // UNI => cUNI
        if (erc20Contract == 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48) return 0x39AA39c021dfbaE8faC545936693aC917d5E7563; // USDC => cUSDC
        if (erc20Contract == 0xdAC17F958D2ee523a2206206994597C13D831ec7) return 0xf650C3d88D12dB855b8bf7D11Be6C55A4e07dCC9; // USDT => cUSDT
        if (erc20Contract == 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599) return 0xC11b1268C1A384e55C48c2391d8d480264A3A7F4; // WBTC => cWBTC
        else revert("CompoundFundController: Supported Compound cToken address not found for this token address");
    }
}
