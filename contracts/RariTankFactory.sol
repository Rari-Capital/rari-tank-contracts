pragma solidity ^0.7.3;

/* Contracts */
import {RariTankDelegator} from "./tanks/RariTankDelegator.sol";

/* Interfaces */
import {IRariTank} from "./interfaces/IRariTank.sol";
import {FactoryStorage} from "./factory/FactoryStorage.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ICErc20} from "./external/compound/ICErc20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IKeep3r} from "./external/keep3r/IKeep3r.sol";
import {IComptroller} from "./external/compound/IComptroller.sol";
import {AggregatorV3Interface} from "./external/chainlink/AggregatorV3Interface.sol";

/* Libraries */
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

/**
    @title RariTankFactory
    @author Jet Jadeja
    @dev Deploys RariTankDelegator implementations
*/
contract RariTankFactory is FactoryStorage, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /*************
     * Modifiers *
     **************/
    modifier keep(address tank) {
        uint256 left = gasleft();
        require(KPR.isKeeper(msg.sender), "::isKeeper: keeper is not registered");
        _;

        uint256 pay;
        (, int256 gasPrice, , , ) = FASTGAS.latestRoundData();

        if (left - gasleft() < 2000000)
            pay = (left - gasleft()).mul(uint256(gasPrice)).div(10).mul(13);
        else pay = (left - gasleft()).mul(uint256(gasPrice)).div(10).mul(12);

        (address asset, uint256 amount) = IRariTank(tank).supplyKeeperPayment(pay);
        if (asset == address(0)) {
            KPR.addCreditETH{value: amount}(address(this));
            KPR.receiptETH(msg.sender, amount.div(1000).mul(997));
        } else {
            IERC20(asset).approve(address(KPR), amount);
            KPR.addCredit(asset, address(this), amount);
            KPR.receipt(asset, msg.sender, amount.div(1000).mul(997));
        }
    }

    receive() external payable {}

    /********************
     * External Functions *
     *********************/

    /** @dev Rebalance the tank */
    function rebalance(address tank, bool useWeth) external keep(tank) {
        IRariTank(tank).rebalance(useWeth);
    }

    /** 
        @dev Emitted when a new Tank has been TankCreated
        @param erc20Contract The Tank's underlying asset
        @param comptroller The address of the FusePool
        @param implementation The Tank's implementation contract address
    */
    event TankCreated(
        address indexed erc20Contract,
        address indexed comptroller,
        address indexed implementation
    );

    /** 
        @dev Deploy a new tank
        @param erc20Contract The Tank's underlying asset
        @param comptroller The address of the FusePool
        @param implementationId The id of the Tank implementation contract address
        @return The address of the new tank
    */
    function deployTank(
        address erc20Contract,
        address comptroller,
        address router,
        uint256 implementationId
    ) external returns (address) {
        // Input validation
        require(DIRECTORY.poolExists(comptroller), "RariTankFactory: Invalid FusePool");
        require(
            getTank[erc20Contract][comptroller][implementationId] == address(0),
            "RariTankFactory: Tank already exists"
        );

        RariTankDelegator tankContract =
            new RariTankDelegator(erc20Contract, comptroller, router, implementationId);

        address tank = address(tankContract);
        tanks.push(tank);
        getTank[erc20Contract][comptroller][implementationId] = tank;

        return tank;
    }

    /** @dev Register a new implementation contract address */
    function newImplementation(address implementation) external onlyOwner {
        initialImplementations.push(implementation);
        implementationById[initialImplementations.length] = implementation;
    }

    /** @dev Upgrade a Tank implementation */
    function updateTankImplemenation(uint256 id, address implementation)
        external
        onlyOwner
    {
        implementationById[id] = implementation;
    }
}
