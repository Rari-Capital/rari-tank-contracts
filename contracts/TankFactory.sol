pragma solidity 0.7.3;

/* Storage */
import {TankFactoryStorage} from "./helpers/factory/TankFactoryStorage.sol";

/* Contracts */
import {TankDelegator} from "./helpers/tanks/TankDelegator.sol";

/* Interfaces */
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
    @title TankFactory
    @author Jet Jadeja <jet@rari.capital>
    @dev Manages Tank deployments, new strategies, and rebalances
*/
contract TankFactory is TankFactoryStorage, Ownable {
    /*************
     * Mofifiers *
     *************/

    /** @dev Checks whether anyone can call a function based on the canDeploy state variable */
    modifier canCall() {
        if (!canDeploy && msg.sender != owner())
            revert("TankFactory: This function can only be called by the owner");
        _;
    }

    /********************
     * External Functions *
     *********************/
    /** @dev Register a new implementaiton contract */
    function newImplementation(address implementation)
        external
        canCall
        returns (uint256)
    {
        require(
            idByImplementation[implementation] == 0,
            "TankFactory: Implementation already exists"
        );

        initialImplementations.push(implementation);
        implementationById[initialImplementations.length] = implementation;
        idByImplementation[implementation] == initialImplementations.length;

        emit NewImplementation(idByImplementation[implementation], implementation);
    }

    /** @dev Deploy a new Tank contract */
    function deployTank(
        address token,
        address comptroller,
        uint256 implementationId
    ) external returns (address tank) {
        // Input Validation

        require(
            getTank[token][comptroller][implementationId] == address(0),
            "TankFactory: Tank already exists"
        );

        require(
            implementationById[implementationId] != address(0),
            "TankFactory: Implementation does not exist"
        );

        bytes memory bytecode = type(TankDelegator).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token, comptroller, implementationId));

        assembly {
            tank := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        emit NewTank(tank, token, comptroller, implementationId);

        tanks.push(tank);
        getTank[token][comptroller][implementationId] = tank;
    }

    function reblanace(address) external {}
}
