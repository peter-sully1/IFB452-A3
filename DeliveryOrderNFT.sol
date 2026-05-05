// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./RoleManager.sol";
import "./AuditLog.sol";

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
    AuditLog public auditLog;
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

    constructor(address _roleManager, address _auditLog) {
        admin = msg.sender;
        roleManager = RoleManager(_roleManager);
        auditLog = AuditLog(_auditLog);
    }

}
