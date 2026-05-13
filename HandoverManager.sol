// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./RoleManager.sol";
import "./DeliveryOrderNFT.sol";

// Custody chain for delivery orders
// Sequence: RESTAURANT → PACKER → DRIVER → RECEIVER → restaurant completes
contract HandoverManager {

    struct HandoverRecord {
        address sender;
        address receiver;
        uint256 timestamp;
    }

    RoleManager public roleManager;
    DeliveryOrderNFT public deliveryOrderNFT;

    // orderId => assigned packer address
    mapping(uint256 => address) public assignedPacker;

    // orderId => assigned driver address
    mapping(uint256 => address) public assignedDriver;

    // orderId => list of handover records
    mapping(uint256 => HandoverRecord[]) private _handovers;

    event PackerAssigned(uint256 indexed orderId, address indexed packer);
    event HandedToDriver(uint256 indexed orderId, address indexed driver);
    event HandedToReceiver(uint256 indexed orderId, address indexed receiver);
    event ReceiptConfirmed(uint256 indexed orderId, address indexed receiver);
    event ExceptionFlagged(uint256 indexed orderId, address indexed reporter, string note);

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

    // Supervisor assigns a packer to a PENDING order
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
    
    // Packer hands order to Driver
    function handoverToDriver(uint256 orderId, address driverAddr)
        external hasRole(RoleManager.Role.PACKER)
    {
        require(assignedPacker[orderId] == msg.sender, "HandoverManager: not the assigned packer");
        require(
            deliveryOrderNFT.getOrderStatus(orderId) == DeliveryOrderNFT.OrderStatus.ASSIGNED,
            "HandoverManager: order must be ASSIGNED"
        );
        roleManager.requireRole(driverAddr, RoleManager.Role.DRIVER);

        assignedDriver[orderId] = driverAddr;

        string memory driverName = roleManager.names(driverAddr);
        deliveryOrderNFT.setDriverName(orderId, driverName);
        deliveryOrderNFT.transferCustody(orderId, driverAddr);

        _recordHandover(orderId, msg.sender, driverAddr);

        emit HandedToDriver(orderId, driverAddr);
    }

    // Driver hands order to Receiver
    function handoverToReceiver(uint256 orderId, address receiverAddr)
        external hasRole(RoleManager.Role.DRIVER)
    {
        require(assignedDriver[orderId] == msg.sender, "HandoverManager: not the assigned driver");
        require(
            deliveryOrderNFT.getOrderStatus(orderId) == DeliveryOrderNFT.OrderStatus.IN_TRANSIT,
            "HandoverManager: order must be IN_TRANSIT"
        );
        roleManager.requireRole(receiverAddr, RoleManager.Role.RECEIVER);

        deliveryOrderNFT.transferCustody(orderId, receiverAddr);

        _recordHandover(orderId, msg.sender, receiverAddr);

        emit HandedToReceiver(orderId, receiverAddr);
    }

    // Receiver confirms receipt
    function confirmReceipt(uint256 orderId)
        external hasRole(RoleManager.Role.RECEIVER)
    {
        require(
            deliveryOrderNFT.getOrderStatus(orderId) == DeliveryOrderNFT.OrderStatus.IN_TRANSIT,
            "HandoverManager: order must be IN_TRANSIT"
        );

        DeliveryOrderNFT.Order memory order = deliveryOrderNFT.getOrder(orderId);
        require(order.currentHolder == msg.sender, "HandoverManager: not the current holder");

        deliveryOrderNFT.markDelivered(orderId);

        _recordHandover(orderId, msg.sender, order.restaurant);

        emit ReceiptConfirmed(orderId, msg.sender);
    }
    
    // Exception reporting PACKER, DRIVER, RECEIVER, or RESTAURANT 
    function reportException(uint256 orderId, string calldata note) external {
        RoleManager.Role callerRole = roleManager.getRole(msg.sender);
        require(
            callerRole == RoleManager.Role.PACKER    ||
            callerRole == RoleManager.Role.DRIVER     ||
            callerRole == RoleManager.Role.RECEIVER   ||
            callerRole == RoleManager.Role.RESTAURANT,
            "HandoverManager: not authorised"
        );

        deliveryOrderNFT.reportException(orderId, note);

        emit ExceptionFlagged(orderId, msg.sender, note);
    }

    // View functions
    function getHandovers(uint256 orderId) external view returns (HandoverRecord[] memory) {
        return _handovers[orderId];
    }

    // Internal helpers
    function _recordHandover(uint256 orderId, address sender, address receiver) internal {
        _handovers[orderId].push(HandoverRecord({
            sender:    sender,
            receiver:  receiver,
            timestamp: block.timestamp
        }));
    }

}
