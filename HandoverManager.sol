// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./RoleManager.sol";
import "./DeliveryOrderNFT.sol";

// Manages the handover sequence for delivery orders.
// Sequence: RESTAURANT places order → SUPERVISOR assigns packer → PACKER hands to DRIVER → DRIVER delivers to RECEIVER
contract HandoverManager {

    // Records each custody handover with sender, receiver, and timestamp
    struct HandoverRecord {
        address sender;
        address receiver;
        uint256 timestamp;
    }

    RoleManager     public roleManager;
    DeliveryOrderNFT public deliveryOrderNFT;

    // orderId => address of assigned packer
    mapping(uint256 => address) public assignedPacker;

    // orderId => address of assigned driver
    mapping(uint256 => address) public assignedDriver;

    // orderId => list of handover records
    mapping(uint256 => HandoverRecord[]) private _handovers;

    // Events
    event PackerAssigned(uint256 indexed orderId, address indexed packer);
    event HandedToDriver(uint256 indexed orderId, address indexed driver);
    event HandedToReceiver(uint256 indexed orderId, address indexed receiver);

    // Restricts a function to callers holding a specific role
    modifier hasRole(RoleManager.Role required) {
        require(
            roleManager.getRole(msg.sender) == required,
            "HandoverManager: wrong role"
        );
        _;
    }

    constructor(address _roleManager, address _deliveryOrderNFT) {
        roleManager      = RoleManager(_roleManager);
        deliveryOrderNFT = DeliveryOrderNFT(_deliveryOrderNFT);
    }

    // Supervisor assigns a registered packer to a PENDING order
    function assignPacker(uint256 orderId, address packerAddr)
        external hasRole(RoleManager.Role.SUPERVISOR)
    {
        require(
            deliveryOrderNFT.getOrderStatus(orderId) == DeliveryOrderNFT.OrderStatus.PENDING,
            "HandoverManager: order must be PENDING"
        );
        roleManager.requireRole(packerAddr, RoleManager.Role.PACKER);

        assignedPacker[orderId] = packerAddr;

        string memory packerName = roleManager.names(packerAddr);
        deliveryOrderNFT.assignPacker(orderId, packerName);

        _recordHandover(orderId, msg.sender, packerAddr);

        emit PackerAssigned(orderId, packerAddr);
    }

    // Packer hands the order to a registered driver
    function handoverToDriver(uint256 orderId, address driverAddr)
        external hasRole(RoleManager.Role.PACKER)
    {
        require(assignedPacker[orderId] == msg.sender, "HandoverManager: not the assigned packer");
        require(
            deliveryOrderNFT.getOrderStatus(orderId) == DeliveryOrderNFT.OrderStatus.IN_TRANSIT,
            "HandoverManager: order must be IN_TRANSIT"
        );
        roleManager.requireRole(driverAddr, RoleManager.Role.DRIVER);

        assignedDriver[orderId] = driverAddr;

        string memory driverName = roleManager.names(driverAddr);
        deliveryOrderNFT.assignDriver(orderId, driverName, driverAddr);

        _recordHandover(orderId, msg.sender, driverAddr);

        emit HandedToDriver(orderId, driverAddr);
    }

    // Driver delivers the order to a registered receiver
    function handoverToReceiver(uint256 orderId, address receiverAddr)
        external hasRole(RoleManager.Role.DRIVER)
    {
        require(assignedDriver[orderId] == msg.sender, "HandoverManager: not the assigned driver");
        require(
            deliveryOrderNFT.getOrderStatus(orderId) == DeliveryOrderNFT.OrderStatus.IN_TRANSIT,
            "HandoverManager: order must be IN_TRANSIT"
        );
        roleManager.requireRole(receiverAddr, RoleManager.Role.RECEIVER);

        deliveryOrderNFT.markDelivered(orderId);

        _recordHandover(orderId, msg.sender, receiverAddr);

        emit HandedToReceiver(orderId, receiverAddr);
    }

    // Returns the full handover history for an order
    function getHandovers(uint256 orderId)
        external view returns (HandoverRecord[] memory)
    {
        return _handovers[orderId];
    }

    // Internal: appends a handover record to the order's history
    function _recordHandover(uint256 orderId, address sender, address receiver) internal {
        _handovers[orderId].push(HandoverRecord({
            sender:    sender,
            receiver:  receiver,
            timestamp: block.timestamp
        }));
    }
}
