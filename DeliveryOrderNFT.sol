// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./RoleManager.sol";

// Each token represents a unique delivery order
// Restaurants mint tokens, HandoverManager updates their state
contract DeliveryOrderNFT {

    enum OrderStatus {
        PENDING,
        ASSIGNED,
        IN_TRANSIT,
        DELIVERED,
        COMPLETED
    }

    struct OrderItem {
        string  name;
        uint256 quantity;
    }

    struct Order {
        uint256 tokenId;
        uint256 totalPriceWei;
        uint256 netWeightGrams;
        uint256 packedAt;
        uint256 driverPickedUpAt;   
        address restaurant;
        address currentHolder;
        OrderStatus status;
        OrderItem[] items;
        string packerName;
        string driverName;
        bool hasException;
        string exceptionNote;
    }

    RoleManager public roleManager;
    address public handoverManager;
    address public admin;

    uint256 private _nextTokenId = 1;

    mapping(uint256 => Order) private _orders;

    event OrderMinted(uint256 indexed tokenId, address indexed restaurant);
    event OrderStatusChanged(uint256 indexed tokenId, OrderStatus newStatus);
    event ExceptionReported(uint256 indexed tokenId, string note);
    event OrderCompleted(uint256 indexed tokenId);

    modifier onlyAdmin() {
        require(msg.sender == admin, "DeliveryOrderNFT: not admin");
        _;
    }

    modifier onlyHandoverManager() {
        require(msg.sender == handoverManager, "DeliveryOrderNFT: not HandoverManager");
        _;
    }

    modifier tokenExists(uint256 tokenId) {
        require(_orders[tokenId].restaurant != address(0), "DeliveryOrderNFT: token does not exist");
        _;
    }

    modifier notCompleted(uint256 tokenId) {
        require(_orders[tokenId].status != OrderStatus.COMPLETED, "DeliveryOrderNFT: order is locked");
        _;
    }

    constructor(address _roleManager, address) {
        admin = msg.sender;
        roleManager = RoleManager(_roleManager);
    }

    // Link the HandoverManager after deployment.
    function setHandoverManager(address _handoverManager) external onlyAdmin {
        handoverManager = _handoverManager;
    }

 
    // Restaurant: place an order
    // Mint a new delivery order token.
    function placeOrder(
        string[] calldata itemNames,
        uint256[] calldata itemQuantities,
        uint256 totalPriceWei,
        uint256 netWeightGrams
    ) external returns (uint256 tokenId) {
        roleManager.requireRole(msg.sender, RoleManager.Role.RESTAURANT);
        require(itemNames.length > 0, "DeliveryOrderNFT: no items");
        require(itemNames.length == itemQuantities.length, "DeliveryOrderNFT: array mismatch");

        tokenId = _nextTokenId++;

        Order storage o  = _orders[tokenId];
        o.tokenId        = tokenId;
        o.restaurant     = msg.sender;
        o.currentHolder  = msg.sender;
        o.status         = OrderStatus.PENDING;
        o.totalPriceWei  = totalPriceWei;
        o.netWeightGrams = netWeightGrams;

        for (uint256 i = 0; i < itemNames.length; i++) {
            o.items.push(OrderItem({ name: itemNames[i], quantity: itemQuantities[i] }));
        }

        emit OrderMinted(tokenId, msg.sender);
    }


    // HandoverManager-only functions
    function assignPacker(uint256 tokenId, string calldata packerName)
        external onlyHandoverManager tokenExists(tokenId) notCompleted(tokenId)
    {
        _orders[tokenId].packerName = packerName;
        _orders[tokenId].packedAt   = block.timestamp;
        _orders[tokenId].status     = OrderStatus.ASSIGNED;
        emit OrderStatusChanged(tokenId, OrderStatus.ASSIGNED);
    }

    function transferCustody(uint256 tokenId, address newHolder)
        external onlyHandoverManager tokenExists(tokenId) notCompleted(tokenId)
    {
        _orders[tokenId].currentHolder = newHolder;
        _orders[tokenId].status        = OrderStatus.IN_TRANSIT;
        emit OrderStatusChanged(tokenId, OrderStatus.IN_TRANSIT);
    }

    function setDriverName(uint256 tokenId, string calldata driverName)
        external onlyHandoverManager tokenExists(tokenId) notCompleted(tokenId)
    {
        _orders[tokenId].driverName       = driverName;
        _orders[tokenId].driverPickedUpAt = block.timestamp;
    }

    function markDelivered(uint256 tokenId)
        external onlyHandoverManager tokenExists(tokenId) notCompleted(tokenId)
    {
        _orders[tokenId].status = OrderStatus.DELIVERED;
        emit OrderStatusChanged(tokenId, OrderStatus.DELIVERED);
    }

    function reportException(uint256 tokenId, string calldata note)
        external onlyHandoverManager tokenExists(tokenId) notCompleted(tokenId)
    {
        _orders[tokenId].hasException  = true;
        _orders[tokenId].exceptionNote = note;
        emit ExceptionReported(tokenId, note);
    }

   
    // Restaurant: complete the order
    // Lock the order permanently once delivery is confirmed.
    function completeOrder(uint256 tokenId)
        external tokenExists(tokenId) notCompleted(tokenId)
    {
        Order storage o = _orders[tokenId];
        require(msg.sender == o.restaurant, "DeliveryOrderNFT: only restaurant can complete");
        require(o.status == OrderStatus.DELIVERED, "DeliveryOrderNFT: not yet delivered");

        o.status = OrderStatus.COMPLETED;

        emit OrderCompleted(tokenId);
    }

  
    // View functions
    function getOrder(uint256 tokenId) external view tokenExists(tokenId) returns (Order memory) {
        return _orders[tokenId];
    }

    function getOrderStatus(uint256 tokenId) external view tokenExists(tokenId) returns (OrderStatus) {
        return _orders[tokenId].status;
    }

    function totalOrders() external view returns (uint256) {
        return _nextTokenId - 1;
    }

}
