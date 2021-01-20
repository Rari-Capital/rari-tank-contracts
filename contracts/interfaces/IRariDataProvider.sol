pragma solidity ^0.7.0;

interface IRariDataProvider {
    /**
        @dev Get 
        @param underlying The address of the underlying ERC20 contract
        @param amount The amount of underlying tokens
    */
    function getMaxUSDBorrowAmount(address underlying, uint256 amount)
        external
        view
        returns (uint256);

    /**
        @dev Given a USD amount, calculate the maximum borrow amount with that sum
        @param underlying The address of the underlying ERC20 contract
        @param usdAmount The USD value available
    */
    function getUSDToUnderlying(address underlying, uint256 usdAmount)
        external
        view
        returns (uint256);

    /**
        @dev Use the exchange rate to convert from CErc20 to Erc20 values
        @param underlying The address of the underlying ERC20 contract
        @param amount The amount of underlying tokens
     */
    function getUnderlyingToCTokens(address underlying, uint256 amount)
        external
        returns (uint256);

    function getCTokensToUnderlying(address underlying, uint256 amount)
        external
        returns (uint256);

    /**
        @dev Retrieve the balanceOfUnderlying from the cTokenContract
        @param underlying The address of the underlying ERC20 contract
        @param account The address whose balance is being returned
    */
    function balanceOfUnderlying(address underlying, address account)
        external
        returns (uint256);

    /**
        @dev Retrieve the borrow balance from the contract
        @param underlying The address of the underlying ERC20 contract
     */
    function borrowBalanceCurrent(address underlying) external returns (uint256);

    /**
    @dev Get the underlying price of the asset scaled by 1e18
    @param underlying The address of the underlying ERC20 contract
    */
    function getUnderlyingPrice(address underlying) external view returns (uint256);

    /**
        @dev Use the exchange rate to calculate the USD price of x tokens
        @param underlying The address of the underlying ERC20 contract
        @param amount The amount of underlying tokens
    */
    function getPrice(address underlying, uint256 amount) external view returns (uint256);
}
