pragma solidity ^0.5.0;

import "./interfaces/IComponentsRegistry.sol";
import "../../common/component/interfaces/IComponent.sol";
import "../../request-verification-layer/permission-module/PermissionModuleMetadata.sol";
import "../../request-verification-layer/permission-module/interfaces/IPermissionModule.sol";
import "../../common/libraries/SafeMath.sol";


/**
* @title Components Registry
*/
contract ComponentsRegistry is IComponentsRegistry, PermissionModuleMetadata {
    // Define libraries
    using SafeMath for uint;

    // Describe component
    struct Component {
        address componentAddress;
        uint listIndex;
    }

    // Declare storage for components by ids
    mapping(bytes4 => Component) components;

    // Declare storage for components ids by addresses
    mapping(address => bytes4) componentsIds;

    // Declare storage for components list
    bytes4[] public componentsList;

    // Write info to the log when new component was added
    event ComponentAdded(address indexed componentAddress, bytes4 id, bytes name);

    // Write info to the log when component was updated
    event ComponentUpdated(address indexed oldAddress, address indexed newAddress);

    // Write info to the log when component was removed
    event ComponentRemoved(address indexed componentAddress);

    /**
    * @notice Verify permission on the method execution
    */
    modifier verifyPermission(address sender, bytes4 sig) {
        address permissionModule = components[PERMISSION_MODULE_ID].componentAddress;
        require(
            IPermissionModule(permissionModule).allowed(sig, sender, address(0)), 
            "Declined by Permission Module."
        );
        _;
    }

    /**
    * @notice Update existing component
    * @param oldAddress Component to update
    * @param newAddress New component address
    */
    function updateComponent(address oldAddress, address newAddress) 
        external
        verifyPermission(msg.sender, msg.sig) 
    {
        require(oldAddress != newAddress, "Invalid addresses.");
        require(componentsIds[oldAddress] != bytes4(0), "Can't update unregistered component");

        bytes4 idOld = IComponent(oldAddress).getComponentId();
        bytes4 idNew = IComponent(newAddress).getComponentId();

        require(idOld == idNew, "Component identifiers must be the same.");

        components[idNew].componentAddress = newAddress;
        componentsIds[newAddress] = idNew;

        delete componentsIds[oldAddress];

        emit ComponentUpdated(oldAddress, newAddress);
    }

    /**
    * @notice Register new components int the system
    * @param componentAddress Address of the new component
    */
    function registerNewComponent(address componentAddress) 
        public
        verifyPermission(msg.sender, msg.sig) 
    {
        require(componentAddress != address(0), "Invalid component address");

        bytes4 id = IComponent(componentAddress).getComponentId();

        require(id != bytes4(""), "Invalid component address.");

        saveComponent(id, componentAddress);
    }

    /**
    * @notice Remove component from the system
    * @param componentAddress Address of the component which will be removed
    */
    function removeComponent(address componentAddress) 
        public
        verifyPermission(msg.sender, msg.sig) 
    {
        require(componentAddress != address(0), "Invalid address.");

        bytes4 id = componentsIds[componentAddress];
        require(id != bytes4(""), "Component not found.");

        uint listIndex = components[id].listIndex;
        uint lastIndex = componentsList.length.sub(1);

        if (lastIndex > 0) {
            bytes4 idToUpdate = componentsList[lastIndex];

            componentsList[listIndex] = idToUpdate;
            components[idToUpdate].listIndex = listIndex;
        }

        delete componentsIds[componentAddress];
        delete components[id];
        componentsList.length = componentsList.length.sub(1);

        emit ComponentRemoved(componentAddress);
    }

    /**
    * @notice Set permission module
    * @param moduleAddress Permission module address
    */
    function initializePermissionModule(address moduleAddress) external {
        require(moduleAddress != address(0), "Invalid component address");

        bytes4 id = IComponent(moduleAddress).getComponentId();

        require(id == PERMISSION_MODULE_ID, "Invalid component.");
        require(
            components[id].componentAddress == address(0),
            "Permission module already initialized."
        );

        saveComponent(id, moduleAddress);
    }

    /**
    * @notice Return component address by component id
    * @param id Component identifier
    */
    function getAddressById(bytes4 id) public view returns (address) {
        return components[id].componentAddress;
    }

    /**
    * @notice Return component name by component id
    * @param id Component identifier
    */
    function getNameById(bytes4 id) public view returns (bytes memory) {
        address componentAddress = components[id].componentAddress;
        return IComponent(componentAddress).getComponentName();
    }

    /**
    * @notice Get the number of components
    */
    function numberOfComponents() public view returns (uint) {
        return componentsList.length;
    }

    /**
    * @notice Save component
    * @param id Component id
    * @param componentAddress Address of the component
    */
    function saveComponent(bytes4 id, address componentAddress) internal {
        uint listIndex = componentsList.length;

        Component memory component = Component({
            componentAddress: componentAddress,
            listIndex: listIndex
        });

        components[id] = component;
        componentsIds[componentAddress] = id;
        componentsList.push(id);

        bytes memory name = IComponent(componentAddress).getComponentName();

        require(name.length > 0, "Invalid component name.");

        emit ComponentAdded(componentAddress, id, name);
    } 
}