// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


// Custody chain for delivery orders
// Sequence: RESTAURANT → PACKER → DRIVER → RECEIVER → restaurant completes
contract HandoverManager {

    // Step 1 - Supervisor assigns a packer to a PENDING order
    function assignPacker(assignPacker(orderID, packerAddr, note );) public {}
        // Requires that the function can only be accessed by a supervisor 
        require(msg.sender == Role [SUPERVISOR], "Only a supervisor can perform this action");
    
    // Step 2 - Packer hands order to Driver
    function handoverToDriver (handoverToDriver(orderID, driverAddress, note );) public {} 
        // Requires that the function can only be accessed by the driver
        require(msg.sender == Role [DRIVER], "Only a driver can perform this action");

    // Step 3 - Driver hands order to Receiver
    function handoverToReceiver (handoverToDriver (orderID, recieverAddr, note);) public {} 
        // Requires that the function can only be accessed by the receiver 
        require(msg.sender == Role [RECEIVER], "Only a receiver can perform this action");

    // Step 4 - Receiver confirms receipt
    function confirmReceipt(orderID) public {}
        // Requires that the function can only be accessed by a supervisor
        require(msg.sender == Role [RECEIVER], "Only a receiver can perform this action");

    // Exception reporting PACKER, DRIVER, RECEIVER, or RESTAURANT 
    function reportException() public {}

}
