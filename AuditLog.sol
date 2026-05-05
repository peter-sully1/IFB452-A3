// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


// Append-only log of significant events, written by other contracts.
contract AuditLog {

    enum EntryType {
        ORDER_CREATED,
        ORDER_ASSIGNED,
        HANDOVER,
        EXCEPTION_REPORTED,
        ORDER_COMPLETED
    }

    struct LogEntry {
        EntryType entryType;
        address   actor;
        string    details;
        uint256   timestamp;
    }

    address public admin;

    mapping(address => bool) public authorisedWriters;

    // orderId => list of log entries for that order
    mapping(uint256 => LogEntry[]) private _entries;

    event EntryWritten(uint256 indexed orderId, EntryType entryType, address indexed actor);

    modifier onlyAdmin() {
        require(msg.sender == admin, "AuditLog: not admin");
        _;
    }

    modifier onlyAuthorised() {
        require(authorisedWriters[msg.sender], "AuditLog: not authorised");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    // Authorise a contract to write log entries.
    function authoriseWriter(address writer) external onlyAdmin {
        authorisedWriters[writer] = true;
    }

    // Append a log entry for an order. Only callable by authorised contracts.
    function writeEntry(
        uint256 orderId,
        EntryType entryType,
        address actor,
        string calldata details
    ) external onlyAuthorised {
        _entries[orderId].push(LogEntry({
            entryType: entryType,
            actor:     actor,
            details:   details,
            timestamp: block.timestamp
        }));

        emit EntryWritten(orderId, entryType, actor);
    }

    // Return all log entries for a given order.
    function getEntriesForOrder(uint256 orderId)
        external
        view
        returns (LogEntry[] memory)
    {
        return _entries[orderId];
    }
}
