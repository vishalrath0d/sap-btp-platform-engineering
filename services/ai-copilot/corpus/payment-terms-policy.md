# ProcureIQ Standard Payment Terms Policy

This policy defines the default payment terms applied to Purchase Orders
unless a supplier-specific contract explicitly overrides them.

## Default terms

Standard payment terms are **Net 30** from the invoice date, meaning payment
is due 30 calendar days after ProcureIQ receives a valid invoice matching the
Purchase Order and confirmed goods receipt. Invoices that do not reference a
valid Purchase Order number are returned to the supplier unpaid.

## Early payment discount

Suppliers may offer an early payment discount, most commonly structured as
**2/10 Net 30**: a 2% discount if payment is made within 10 days of the
invoice date, with the full amount due at 30 days otherwise. Early payment
discounts must be captured in the supplier's contract record, not assumed
from an invoice line item alone.

## Late payment

Payments made after the due date accrue interest at a rate defined by the
supplier's contract, defaulting to 1.5% per month on the outstanding balance
if no contract-specific rate is set. Repeated late payment on ProcureIQ's side
should be escalated to Finance Operations, not resolved by extending future
Purchase Order terms unilaterally.

## Currency and international suppliers

Purchase Orders are issued in the currency agreed in the supplier's contract.
For suppliers without a currency clause, USD is the default. Suppliers in the
EU are commonly paid in EUR; suppliers in China are commonly paid in USD
unless a CNY clause exists in their specific contract.

## High-risk suppliers

Suppliers with a riskRating of HIGH are moved to **prepayment or Net 15**
terms at Procurement's discretion until their risk rating improves, to limit
ProcureIQ's exposure on undelivered goods.
