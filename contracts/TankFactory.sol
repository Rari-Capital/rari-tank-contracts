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
        uint256 id = initialImplementations.length;

        implementationById[id] = implementation;
        idByImplementation[implementation] = id;
        ownerByImplementation[initialImplementations.length] = msg.sender;

        emit NewImplementation(idByImplementation[implementation], implementation);
    }

    /** @dev Deploy a new Tank contract */
    function deployTank(uint256 implementationId, bytes memory data)
        external
        returns (address)
    {
        // Input Validation

        require(
            implementationById[implementationId] != address(0),
            "TankFactory: Implementation does not exist"
        );

        bytes32 salt = keccak256(abi.encodePacked(data, implementationId));
        TankDelegator tank = new TankDelegator{salt: salt}(implementationId, data);

        emit NewTank(address(tank), data, implementationId);
        tanks.push(address(tank));
    }

    /** @dev Modify the canCall variable, changing permissions for Tank creation  */
    function changePermissions(bool newPermissions) external onlyOwner() {
        canDeploy = newPermissions;
    }

    /** @dev Transfer ownership of an implementation */
    function transferImplementationOwnership(uint256 id, address newOwner) external {
        require(
            ownerByImplementation[id] == msg.sender,
            "TankFactory: Must be called by the implementation owner"
        );

        ownerByImplementation[id] = newOwner;
        emit ImplementationOwnerTransfered(id, newOwner);
    }

    /** @dev Upgrade the implementation address */
    function upgradeImplementation(uint256 id, address implementation) external {
        require(
            ownerByImplementation[id] == msg.sender,
            "TankFactory: Must be called by the implementation owner"
        );

        implementationById[id] = implementation;
        emit ImplementationUpgraded(id, implementation);
    }

    function getTanks() external view returns (address[] memory) {
        return tanks;
    }
}
