pragma solidity 0.7.3;

import {ICErc20} from "./ICErc20.sol";

/**
    @title Compound's PriceFeed Contract
    @author Compound
 */
interface IPriceFeed {
    function getUnderlyingPrice(ICErc20) external view returns (uint256);
}
