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

/** 
    @title Tank
    @author Jet Jadeja <jet@rari.capital>
    @dev The default Tank contract, supplies an asset to Fuse, borrows another asset, and earns interest on it.
*/
contract Tank is TankStorage, ERC20Upgradeable {
    /***************
     * Constructor *
     ***************/
    /** @dev Initialize the Tank contract (acts as a constructor) */
    function initialize(address _token, address _comptroller) external {
        require(!initalized, "Tank: Initialization has already occured");

        token = _token;
        comptroller = _comptroller;

        __ERC20_init(
            string(abi.encodePacked("Tank ", ERC20Upgradeable(_token).name())),
            string(abi.encodePacked("rtt-", ERC20Upgradeable(_token).symbol(), "-DAI"))
        );

        /* 
            Ideally, this would be a constant state variable, 
            but since this is a proxy contract, it would be unsafe
        */
        borrowing = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
        cToken = address(IComptroller(_comptroller).cTokensByUnderlying(_token));

        require(cToken != address(0), "Unsupported asset");
        require(
            address(IComptroller(_comptroller).cTokensByUnderlying(borrowing)) !=
                address(0),
            "Unsupported borrow asset"
        );
    }
}
