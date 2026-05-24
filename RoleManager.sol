// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Registers stakeholder roles and verifies them for other contracts.
contract RoleManager {

    // Stored as 0-5
    enum Role {
        NONE,
        RESTAURANT,
        SUPERVISOR,
        PACKER,
        DRIVER,
        RECEIVER
    }

    address public admin;

    mapping(address => Role) public roles;
    mapping(address => string) public names;

    event RoleGranted(address indexed account, Role role, string name);

    modifier onlyAdmin() {
        require(msg.sender == admin, "RoleManager: not admin");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    // Register a stakeholder with a role and display name.
    function registerStakeholder(
        address account,
        Role role,
        string calldata name
    ) external onlyAdmin {
        require(role != Role.NONE, "RoleManager: invalid role");
        require(roles[account] == Role.NONE, "RoleManager: already registered");

        roles[account] = role;
        names[account] = name;

        emit RoleGranted(account, role, name);
    }

    // Returns the role of an address
    function getRole(address account) external view returns (Role) {
        return roles[account];
    }

    // Reverts if the address does not hold the expected role
    function requireRole(address account, Role expected) external view {
        require(roles[account] == expected, "RoleManager: wrong role");
    }
}
