Deploy RoleManager → copy address
Deploy AuditLog → copy address
Deploy DeliveryOrderNFT(roleManagerAddr, auditLogAddr)
Deploy HandoverManager(roleManagerAddr, deliveryOrderNFTAddr, auditLogAddr)
Call deliveryOrderNFT.setHandoverManager(handoverManagerAddr)
Call auditLog.authoriseWriter(deliveryOrderNFTAddr)
Call auditLog.authoriseWriter(handoverManagerAddr)
Register your test accounts via roleManager.registerStakeholder(addr, role, name)

Restaurant    → placeOrder(items, quantities, units, weight)  [with ETH value]
Supervisor    → assignPacker(orderId, packerAddr, note)
Packer        → handoverToDriver(orderId, driverAddr, note)
Driver        → handoverToReceiver(orderId, receiverAddr, note)
Receiver      → confirmReceipt(orderId, note)
Restaurant    → completeOrder(orderId)   [on DeliveryOrderNFT directly]