# Deployment Steps
 
1. Deploy `RoleManager` → copy address
2. Deploy `AuditLog` → copy address
3. Deploy `DeliveryOrderNFT(roleManagerAddr, auditLogAddr)`
4. Deploy `HandoverManager(roleManagerAddr, deliveryOrderNFTAddr, auditLogAddr)`
5. Call `deliveryOrderNFT.setHandoverManager(handoverManagerAddr)`
6. Call `auditLog.authoriseWriter(deliveryOrderNFTAddr)`
7. Call `auditLog.authoriseWriter(handoverManagerAddr)`
8. Register your test accounts via `roleManager.registerStakeholder(addr, role, name)`
# Workflow
 
| Role | Action |
|------|--------|
| Restaurant | `placeOrder(items, quantities, units, weight)` *(with ETH value)* |
| Supervisor | `assignPacker(orderId, packerAddr, note)` |
| Packer | `handoverToDriver(orderId, driverAddr, note)` |
| Driver | `handoverToReceiver(orderId, receiverAddr, note)` |
| Receiver | `confirmReceipt(orderId, note)` |
| Restaurant | `completeOrder(orderId)` *(on `DeliveryOrderNFT` directly)* |
 
# Note
 
RoleManager & AuditLog should be fine for now.
Still figuring DeliveryOrderNFT & HandoverManager.
