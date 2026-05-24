// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./RoleManager.sol";

// Stores and manages delivery orders for the Block Delivery Logistics system.
// Restaurants create orders; HandoverManager updates their status and details.
contract DeliveryOrderNFT {

    // Tracks where the order is in the delivery lifecycle
    enum OrderStatus {
        PENDING,
        IN_TRANSIT,
        DELIVERED
    }

    // Represents a single delivery order
    struct Order {
        uint256 orderId;
        address restaurant;
        address currentHolder;
        string  itemDescription;
        string  packerName;
        string  driverName;
        uint256 createdAt;
        OrderStatus status;
    }

    RoleManager public roleManager;
    address public admin;
    address public handoverManager;

    // Counter to generate unique order IDs (matches course pattern)
    uint256 public orderCount;

    // orderId => Order
    mapping(uint256 => Order) public orders;

    // Events
    event OrderCreated(uint256 indexed orderId, address indexed restaurant, string itemDescription);
    event StatusChanged(uint256 indexed orderId, OrderStatus newStatus);
    event PackerAssigned(uint256 indexed orderId, string packerName);
    event DriverAssigned(uint256 indexed orderId, string driverName);

    // Restricts admin-only functions to the deployer
    modifier onlyAdmin() {
        require(msg.sender == admin, "DeliveryOrderNFT: not admin");
        _;
    }

    // Restricts state-change functions to HandoverManager contract
    modifier onlyHandoverManager() {
        require(msg.sender == handoverManager, "DeliveryOrderNFT: not HandoverManager");
        _;
    }

    // Reverts if the order does not exist
    modifier orderExists(uint256 orderId) {
        require(orderId > 0 && orderId <= orderCount, "DeliveryOrderNFT: order does not exist");
        _;
    }

    constructor(address _roleManager) {
        admin = msg.sender;
        roleManager = RoleManager(_roleManager);
    }

    // Called once after HandoverManager is deployed, to link the two contracts
    function setHandoverManager(address _handoverManager) external onlyAdmin {
        handoverManager = _handoverManager;
    }

    // Restaurant places a new order
    function placeOrder(string calldata itemDescription) external {
        roleManager.requireRole(msg.sender, RoleManager.Role.RESTAURANT);
        require(bytes(itemDescription).length > 0, "DeliveryOrderNFT: description required");

        orderCount++;

        Order storage o = orders[orderCount];
        o.orderId        = orderCount;
        o.restaurant     = msg.sender;
        o.currentHolder  = msg.sender;
        o.itemDescription = itemDescription;
        o.createdAt      = block.timestamp;
        o.status         = OrderStatus.PENDING;

        emit OrderCreated(orderCount, msg.sender, itemDescription);
    }

    // HandoverManager sets the packer name and moves status to IN_TRANSIT
    function assignPacker(uint256 orderId, string calldata packerName)
        external onlyHandoverManager orderExists(orderId)
    {
        require(
            orders[orderId].status == OrderStatus.PENDING,
            "DeliveryOrderNFT: order must be PENDING"
        );
        orders[orderId].packerName = packerName;
        orders[orderId].status     = OrderStatus.IN_TRANSIT;

        emit PackerAssigned(orderId, packerName);
        emit StatusChanged(orderId, OrderStatus.IN_TRANSIT);
    }

    // HandoverManager sets the driver name and updates the current holder
    function assignDriver(uint256 orderId, string calldata driverName, address driverAddr)
        external onlyHandoverManager orderExists(orderId)
    {
        require(
            orders[orderId].status == OrderStatus.IN_TRANSIT,
            "DeliveryOrderNFT: order must be IN_TRANSIT"
        );
        orders[orderId].driverName    = driverName;
        orders[orderId].currentHolder = driverAddr;

        emit DriverAssigned(orderId, driverName);
    }

    // HandoverManager marks the order as delivered
    function markDelivered(uint256 orderId)
        external onlyHandoverManager orderExists(orderId)
    {
        require(
            orders[orderId].status == OrderStatus.IN_TRANSIT,
            "DeliveryOrderNFT: order must be IN_TRANSIT"
        );
        orders[orderId].status = OrderStatus.DELIVERED;

        emit StatusChanged(orderId, OrderStatus.DELIVERED);
    }

    // Read order details by ID
    function getOrder(uint256 orderId)
        external view orderExists(orderId)
        returns (Order memory)
    {
        return orders[orderId];
    }

    // Read just the status of an order
    function getOrderStatus(uint256 orderId)
        external view orderExists(orderId)
        returns (OrderStatus)
    {
        return orders[orderId].status;
    }
}
