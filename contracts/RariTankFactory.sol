pragma solidity ^0.7.3;

/* Contracts */
import {RariTankDelegator} from "./RariTankDelegator.sol";

/* Interfaces */
import {IRariTankFactory} from "./interfaces/IRariTankFactory.sol";
import {IRariTank} from "./interfaces/IRariTank.sol";

import {ICErc20} from "./external/compound/ICErc20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IComptroller} from "./external/compound/IComptroller.sol";
import {IFusePoolDirectory} from "./external/fuse/IFusePoolDirectory.sol";

import {IKeep3r} from "./external/keep3r/IKeep3r.sol";
import {AggregatorV3Interface} from "./external/chainlink/AggregatorV3Interface.sol";

import "hardhat/console.sol";

/* Libraries */
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

/**
    @title RariTankFactory
    @author Jet Jadeja
    @dev Deploys RariTankDelegator implementations
*/
contract RariTankFactory is IRariTankFactory {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /*************
     * Constants *
     *************/
    IKeep3r internal constant KPR = IKeep3r(0x1cEB5cB57C4D4E2b2433641b95Dd330A33185A44);
    AggregatorV3Interface constant FASTGAS =
        AggregatorV3Interface(0x169E633A2D1E6c10dD91238Ba11c4A708dfEF37C);

    /*************
     * Variables *
     *************/

    /** @dev The address of the FusePoolDirectory */
    address private fusePoolDirectory;

    /** @dev An array containing the address of all tanks */
    address[] public tanks;

    /** @dev Maps the token to a map from Comptroller to a map from implementation to tank */
    mapping(address => mapping(address => mapping(address => address))) public getTank;

    /** @dev Maps tokens to an array of tanks */
    mapping(address => address[]) private _getTanksByToken;

    /** @dev Maps a Comptroller to an array of tanks */
    mapping(address => address[]) private _getTanksByComptroller;

    /** @dev Maps an implementation to an array of tanks */
    mapping(address => address[]) private _getTanksByImplementation;

    /** @dev Maps token to a map from implementation to an array of tanks */
    mapping(address => mapping(address => address[]))
        private _getTanksByTokenAndImplementation;

    /** @dev Maps the token to a map from Comptroller to an array of tanks */
    mapping(address => mapping(address => address[]))
        private _getTanksByTokenAndComptroller;

    /** @dev Maps the Comptroller to a map from implementation to an array of tanks */
    mapping(address => mapping(address => address[]))
        private _getTanksByComptrollerAndImplementation;

    /*************
     * Modifiers *
     **************/
    modifier keep(address tank) {
        uint256 left = gasleft();
        require(KPR.isKeeper(msg.sender), "::isKeeper: keeper is not registered");
        _;
        //(, int256 gasPrice, , , ) = FASTGAS.latestRoundData();
        uint256 gasPrice = 100 * 1e9;

        uint256 pay = (left - gasleft()).mul(uint256(gasPrice)).div(100).mul(125);
        (address asset, uint256 amount) = IRariTank(tank).supplyKeeperPayment(pay);

        if (asset == address(0)) {
            KPR.addCreditETH{value: pay.div(1000).mul(1005)}(address(this));
            KPR.receiptETH(msg.sender, pay);
        } else {
            IERC20(asset).safeTransferFrom(tank, address(this), amount);
            IERC20(asset).approve(address(KPR), amount);

            KPR.addCredit(asset, address(this), amount);
            KPR.receipt(asset, msg.sender, amount.div(1000).mul(997));
        }
    }

    /***************
     * Constructor *
     ***************/
    constructor(address _fusePoolDirectory) {
        fusePoolDirectory = _fusePoolDirectory;
    }

    /********************
     * External Functions *
     *********************/

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
    function deployTank(
        address erc20Contract,
        address comptroller,
        address router,
        address implementation
    ) external override returns (address) {
        // Input validation
        require(
            IFusePoolDirectory(fusePoolDirectory).poolExists(comptroller),
            "RariTankFactory: Invalid FusePool"
        );

        require(
            getTank[erc20Contract][comptroller][implementation] == address(0),
            "RariTankFactory: Tank already exists"
        );

        RariTankDelegator tank =
            new RariTankDelegator(erc20Contract, comptroller, router, implementation);

        address tankAddr = address(tank);

        tanks.push(tankAddr);
        getTank[erc20Contract][comptroller][implementation] = tankAddr;

        _getTanksByToken[erc20Contract].push(tankAddr);
        _getTanksByComptroller[comptroller].push(tankAddr);
        _getTanksByImplementation[implementation].push(tankAddr);

        _getTanksByTokenAndComptroller[erc20Contract][comptroller].push(tankAddr);
        _getTanksByTokenAndImplementation[erc20Contract][implementation].push(tankAddr);
        _getTanksByComptrollerAndImplementation[comptroller][implementation].push(
            tankAddr
        );

        return tankAddr;
    }

    /*****************
     * View Functions *
     ******************/
    function getTanksByToken(address token) external view returns (address[] memory) {
        return _getTanksByToken[token];
    }

    function getTanksByImplementation(address impl)
        external
        view
        returns (address[] memory)
    {
        return _getTanksByImplementation[impl];
    }

    function getTanksByComptroller(address comptroller)
        external
        view
        returns (address[] memory)
    {
        return _getTanksByComptroller[comptroller];
    }

    function getTanksByTokenAndImplementation(address token, address impl)
        external
        view
        returns (address[] memory)
    {
        return _getTanksByTokenAndImplementation[token][impl];
    }

    function getTanksByTokenAndComptroller(address token, address comptroller)
        external
        view
        returns (address[] memory)
    {
        return _getTanksByTokenAndComptroller[token][comptroller];
    }

    function getTanksByComptrollerAndImplementation(address comptroller, address impl)
        external
        view
        returns (address[] memory)
    {
        return _getTanksByTokenAndComptroller[comptroller][impl];
    }

    receive() external payable {}
}
