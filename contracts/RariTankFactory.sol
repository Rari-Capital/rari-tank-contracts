pragma solidity ^0.7.3;

/* Contracts */
import {RariTankDelegator} from "./RariTankDelegator.sol";

/* Interfaces */
import {IRariTankFactory} from "./interfaces/IRariTankFactory.sol";
import {IRariTank} from "./interfaces/IRariTank.sol";

import {ICErc20} from "./external/compound/ICErc20.sol";
import {IComptroller} from "./external/compound/IComptroller.sol";
import {IFusePoolDirectory} from "./external/fuse/IFusePoolDirectory.sol";

import {IKeep3r} from "./external/keep3r/IKeep3r.sol";
import {AggregatorV3Interface} from "./external/chainlink/AggregatorV3Interface.sol";

/* Libraries */
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

/**
    @title RariTankFactory
    @author Jet Jadeja
    @dev Deploys RariTankDelegator implementations
*/
contract RariTankFactory is IRariTankFactory {
    using SafeMath for uint256;

    /*************
    * Constants *
    *************/
    IKeep3r internal constant KPR = IKeep3r(0x1cEB5cB57C4D4E2b2433641b95Dd330A33185A44);
    AggregatorV3Interface constant FASTGAS = AggregatorV3Interface(
        0x169E633A2D1E6c10dD91238Ba11c4A708dfEF37C
    );

    /*************
    * Variables *
    *************/

    /** @dev The address of the FusePoolDirectory */
    address private fusePoolDirectory;

    /** @dev Maps the underlying token to a map from implementation to tank  */
    mapping(address => mapping(address => address)) private tankByImplementation;

    /** @dev Maps the address of an implementation to an array of tanks that use it */
    mapping(address => address[]) private tanksByImplementation;

    /** @dev Maps the underlying token to an array of tanks supporting it */
    mapping(address => address[]) private tanksByUnderlying;

    /*************
     * Modifiers *
    **************/
    modifier keep(address tank) {
        uint256 left = gasleft();
        require(KPR.isKeeper(msg.sender), "::isKeeper: keeper is not registered");
        _;
        (, int256 gasPrice, , , ) = FASTGAS.latestRoundData();
        uint256 pay = (left - gasleft()).mul(uint(gasPrice));
        IRariTank(tank).supplyKeeperPayment(
            pay.div(1000).mul(1005)
        );
        KPR.addCreditETH{value: pay.div(1000).mul(1005)}(address(this));
        KPR.receiptETH(msg.sender, pay);
    }

    /***************
     * Constructor *
    ***************/
    constructor(address _fusePoolDirectory) {
        fusePoolDirectory = _fusePoolDirectory;
    }

    /**
    @dev Rebalance the tank
    */
    function rebalance(address tank, bool useWeth) external override keep(tank) {
        IRariTank(tank).rebalance(useWeth);
    }

    /** 
        @dev Deploy a new tank
        @param erc20Contract The underlying asset
        @param comptroller The FusePool's comptroller
        @param implementation The tank's delegate contract
        @return The address of the new tank
    */
    function deployTank(address erc20Contract, address comptroller, address implementation) external override returns (address) {
        // Input validation
        require(IFusePoolDirectory(fusePoolDirectory).poolExists(comptroller), "RariTankFactory: Invalid Pool");

        RariTankDelegator tank = new RariTankDelegator(
            erc20Contract, 
            comptroller,
            implementation
        );

        address tankAddr = address(tank);

        tankByImplementation[erc20Contract][implementation] = tankAddr;
        tanksByImplementation[implementation].push(tankAddr);
        tanksByUnderlying[erc20Contract].push(tankAddr);

        return tankAddr;
    }

    /*****************
    * View Functions *
    ******************/
    /** 
        @dev Given a token
        @return a list of tanks that support it 
    */
    function getTanksByUnderlying(address erc20Contract) external view returns (address[] memory) {
        address[] memory tanks = tanksByUnderlying[erc20Contract];
        return tanks;
    }

    /** 
        @dev Given an token and implementation address 
        @return tank that supports the token and uses the implementation contract
    */
    function getTankByImplementation(address erc20Contract, address implementation) external view returns (address) {
        return tankByImplementation[erc20Contract][implementation];
    }

    receive() external payable {}
}