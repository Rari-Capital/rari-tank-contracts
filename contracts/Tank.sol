pragma solidity 0.7.3;

/* Storage */
import {TankStorage} from "./helpers/tanks/TankStorage.sol";
import {ITank} from "./interfaces/ITank.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/Initializable.sol";

/* Interfaces */
import {
    ERC20Upgradeable
} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

import {IComptroller} from "./external/compound/IComptroller.sol";
import {ICErc20} from "./external/compound/ICErc20.sol";
import {IPriceFeed} from "./external/compound/IPriceFeed.sol";

import {IFusePoolDirectory} from "./external/fuse/IFusePoolDirectory.sol";

/** 
    @title Tank
    @author Jet Jadeja <jet@rari.capital>
    @dev The default Tank contract, supplies an asset to Fuse, borrows another asset, and earns interest on it.
*/
contract Tank is TankStorage, ERC20Upgradeable {
    IFusePoolDirectory internal constant DIRECTORY =
        IFusePoolDirectory(0x835482FE0532f169024d5E9410199369aAD5C77E);

    /***************
     * Constructor *
     ***************/
    /** @dev Initialize the Tank contract (acts as a constructor) */
    function initialize(address _token, address _comptroller) external {
        require(!initalized, "Tank: Initialization has already occured");
        require(
            DIRECTORY.poolExists(comptroller),
            "TankFactory: Invalid Comptroller address"
        );

        token = _token;
        comptroller = _comptroller;

        /* 
            Ideally, this would be a constant state variable, 
            but since this is a proxy contract, it would be unsafe
        */
        address borrowing = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
        string memory borrowSymbol = ERC20Upgradeable(borrowing).symbol();
        cToken = address(IComptroller(_comptroller).cTokensByUnderlying(_token));

        __ERC20_init(
            string(abi.encodePacked("Tank ", ERC20Upgradeable(_token).name())),
            string(
                abi.encodePacked("rtt-", ERC20Upgradeable(_token).symbol(), borrowSymbol)
            )
        );

        require(cToken != address(0), "Unsupported asset");
        require(
            address(IComptroller(_comptroller).cTokensByUnderlying(borrowing)) !=
                address(0),
            "Unsupported borrow asset"
        );
    }

    /*************
     * Mofifiers *
     *************/

    modifier onlyFactory() {
        require(msg.sender == factory, "Tank: Can only be called by the factory");
        _;
    }

    /********************
     * External Functions *
     *********************/
    /** @dev Deposit into the Tank */
    function deposit(uint256 amount) external {}

    /** @dev Deposit devs into the Tanks */
    function withdraw(uint256 amount) external {}

    /** @dev Rebalance the Tank, includes calibrating  */
    function rebalance(bool useWeth) external onlyFactory {}

    /********************
     * Public Functions *
     ********************/
    /** @dev Get the tank Token Exchange rate */
    function exchangeRateCurrent() external returns (uint256) {
        uint256 totalSupply = totalSupply();
        uint256 mantissa = 18 - ERC20Upgradeable(token).decimals();
        //uint256 balance = FusePoolController.balanceOfUnderlying(cToken).mul(10**mantissa);
    }
}
