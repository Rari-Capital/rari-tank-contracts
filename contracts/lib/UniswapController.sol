pragma solidity ^0.7.0;

import "../external/uniswapv2/IUniswapV2Pair.sol";
import "../external/uniswapv2/IUniswapV2Factory.sol";
import "../external/uniswapv2/UniswapV2Library.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

library UniswapController {
    using SafeERC20 for IERC20;

    address constant factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

    function swapTokens(address[] memory path, uint256 amount)
        internal
        returns (uint256)
    {
        require(amount > 0, "UniswapController: Amount cannot be 0");
        require(path[0] != path[1], "UniController: Assets cannot be the same");

        uint256[] memory amounts = UniswapV2Library.getAmountsOut(factory, amount, path);
        address pair = UniswapV2Library.pairFor(factory, path[0], path[1]);
        IERC20(path[0]).safeTransfer(pair, amounts[0]);
        swap(amounts, path);

        return amounts[1];
    }

    function swap(uint256[] memory amounts, address[] memory path) internal {
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0, ) = UniswapV2Library.sortTokens(input, output);
            uint256 amountOut = amounts[i + 1];
            //prettier-ignore
            (uint256 amount0Out, uint256 amount1Out) = input == token0 ? (uint256(0), amountOut) : (amountOut, uint256(0));
            //prettier-ignore
            address to = i < path.length - 2 ? UniswapV2Library.pairFor(factory, output, path[i + 2]) : address(this);

            IUniswapV2Pair(UniswapV2Library.pairFor(factory, input, output)).swap(
                amount0Out,
                amount1Out,
                to,
                new bytes(0)
            );
        }
    }
}