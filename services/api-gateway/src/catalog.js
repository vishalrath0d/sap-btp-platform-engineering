'use strict';

// Shaped like an SAP API Business Hub catalog entry - what a real
// discoverable API product listing carries (name, description, version,
// auth requirements, rate limits, and its endpoint list) rather than
// leaving API consumers to reverse-engineer the OData service directly.
module.exports = {
  name: 'ProcureIQ Procurement API',
  version: '0.1.0',
  description:
    'Purchase Requisition to Purchase Order workflow API, gateway-managed (API key auth, rate limiting) in front of procurement-core.',
  baseUrl: '/api/v1',
  authentication: {
    type: 'API Key',
    header: 'X-API-Key',
    note: 'Additive, not a replacement: procurement-core still enforces its own RBAC (Basic Auth locally, XSUAA once deployed) on every request the gateway forwards.',
  },
  rateLimit: {
    windowSeconds: 60,
    maxRequests: 10,
    scope: 'per API key',
  },
  endpoints: [
    { method: 'GET', path: '/PurchaseRequisitions', description: 'List purchase requisitions' },
    { method: 'POST', path: '/PurchaseRequisitions', description: 'Create a purchase requisition' },
    { method: 'POST', path: "/PurchaseRequisitions({id})/ProcurementService.submit", description: 'Submit a requisition for approval' },
    { method: 'POST', path: "/PurchaseRequisitions({id})/ProcurementService.approve", description: 'Approve a submitted requisition' },
    { method: 'POST', path: "/PurchaseRequisitions({id})/ProcurementService.rejectRequisition", description: 'Reject a submitted requisition' },
    { method: 'GET', path: '/Suppliers', description: 'List suppliers' },
    { method: 'POST', path: '/syncLegacySuppliers', description: 'Sync suppliers from the legacy on-prem system' },
  ],
};
