# Block Delivery Logistics
 
A blockchain-based food delivery logistics system where each order is represented as a unique on-chain token that passes through a verified custody chain from restaurant to warehouse to driver to receiver.
 
---
 
## Contracts
 
| Contract | Purpose |
|---|---|
| `RoleManager.sol` | Registers stakeholder wallet addresses with roles |
| `DeliveryOrderNFT.sol` | Mints and manages delivery order tokens |
| `HandoverManager.sol` | Orchestrates the custody chain and enforces sequence |
 
## Deployment Order
 
Deploy contracts in this exact sequence:
 
1. Deploy `RoleManager`
2. Deploy `DeliveryOrderNFT(roleManagerAddr)`
3. Deploy `HandoverManager(roleManagerAddr, deliveryOrderNFTAddr)`
4. Call `deliveryOrderNFT.setHandoverManager(handoverManagerAddr)`
5. Register stakeholders via `roleManager.registerStakeholder(addr, role, name)`
## Roles
 
```
0 = NONE
1 = RESTAURANT
2 = SUPERVISOR
3 = PACKER
4 = DRIVER
5 = RECEIVER
```
 
## Order Lifecycle
 
```
1. RESTAURANT   → placeOrder(itemNames, itemQuantities, totalPriceWei, netWeightGrams)
2. SUPERVISOR   → assignPacker(orderId, packerAddr)
3. PACKER       → handoverToDriver(orderId, driverAddr)
4. DRIVER       → handoverToReceiver(orderId, receiverAddr)
5. RECEIVER     → confirmReceipt(orderId)
6. RESTAURANT   → completeOrder(orderId)   [called on DeliveryOrderNFT directly]
```
 
Any stakeholder can call `reportException(orderId, note)` on `HandoverManager` at any point.
 
## Order Statuses
 
```
PENDING → ASSIGNED → IN_TRANSIT → DELIVERED → COMPLETED
```
 