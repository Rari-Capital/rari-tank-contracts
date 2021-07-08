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
    @dev Manages Tank deployments and the registration of new strategies
*/
contract TankFactory is TankFactoryStorage, Ownable {
    /*************
     * Mofifiers *
     *************/

    /** @dev Checks whether anyone can call a function based on the canDeploy state variable */
    modifier canCall() {
        if (!canDeploy && msg.sender != owner()) revert("TankFactory: This function can only be called by the owner");
        _;
    }

    /********************
     * External Functions *
     *********************/
    /** 
        @dev Register a new implementation contract
        @param implementation address of the implementation contract
    */
    function newImplementation(address implementation) external canCall {
        require(idByImplementation[implementation] == 0, "TankFactory: Implementation already exists");
        require(implementation != address(0), "TankFactory: Implementation cannot be the zero address");

        initialImplementations.push(implementation); // Push initial implementation address
        uint256 id = initialImplementations.length; // Calculate the implementation ID

        implementationById[id] = implementation;
        idByImplementation[implementation] = id;
        ownerByImplementation[initialImplementations.length] = msg.sender;

        emit NewImplementation(idByImplementation[implementation], implementation);
    }

    /** 
        @dev Deploy a new Tank contract
        @param id The id of the implementation contract
        @param data A bytes parameter that is passed to the contract's constructor
    */
    function deployTank(uint256 id, bytes memory data) external returns (address) {
        require(implementationById[id] != address(0), "TankFactory: Implementation does not exist");

        bytes32 salt = keccak256(abi.encodePacked(id, data));
        TankDelegator tank = new TankDelegator{salt: salt}(id, data);

        tanks.push(address(tank));
        idByTank[address(tank)] = id;

        emit NewTank(address(tank), data, id);
    }

    /** @dev Modify the canCall variable, changing permissions for implementation registration  */
    function changePermissions(bool newPermissions) external onlyOwner() {
        canDeploy = newPermissions;
    }

    /** 
        @dev Transfer ownership of an implementation
        @param id The id of the implementation contract
        @param newOwner the new implementation owner
    */
    function transferImplementationOwnership(uint256 id, address newOwner) external {
        require(newOwner != address(0), "TankFactory: New owner cannot be the zero address");
        require(ownerByImplementation[id] == msg.sender, "TankFactory: Must be called by the implementation owner");

        ownerByImplementation[id] = newOwner;
        emit ImplementationOwnerTransferred(id, newOwner);
    }

    /** 
        @dev Upgrade the implementation address
        @param id The id of the implementation contract
        @param implementation The address of the new implementation contract
    */
    function upgradeImplementation(uint256 id, address implementation) external {
        require(ownerByImplementation[id] == msg.sender, "TankFactory: Must be called by the implementation owner");
        require(implementation != address(0), "TankFactory: Implementation cannot be the zero address");

        implementationById[id] = implementation;
        emit ImplementationUpgraded(id, implementation);
    }

    /** @dev Given a tank, get its corresponding implementation address */
    function getImplementation(address tank) external view returns (address) {
        return implementationById[idByTank[tank]];
    }

    /** @return an array of all Tanks */
    function getTanks() external view returns (address[] memory) {
        return tanks;
    }
}
