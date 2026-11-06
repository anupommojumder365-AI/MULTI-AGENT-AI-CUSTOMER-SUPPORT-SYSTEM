# Operational API

Base: https://yhssfzpsujhtngjrkauv.supabase.co/rest/v1/rpc/
Use the project publishable key plus an authenticated staff bearer token. The browser must never use the service-role key. RLS is the authorization boundary. These are staff APIs, not customer self-service endpoints.

| RPC | Access | Purpose |
|---|---|---|
| novacart_dashboard | staff | Operational lists and metrics |
| novacart_order_api | staff | action: customer_lookup, order_lookup, shipping_status, order_history, refund_eligibility, refund_status; customer and order_number parameters |
| novacart_approve | approver/admin | refund UUID, decision approve/reject, note; simulated only |
| novacart_prepare | service | p envelope; create ticket, identify verified order and deduplicate |
| novacart_finalize | service | p context with eight role results; update ticket and request refund review |
| novacart_inbound_unverified | service | external_id, message; review ticket only |
| novacart_record_failure | service | p error context; log and escalate |
| novacart_retry_case | service | ticket UUID; bounded recovery context |
| novacart_maintenance | service | Stale-ticket recovery and metrics |

Exact SQL signatures and return structures are authoritative in migrations. Missing records return an error object or empty result; malformed privileged requests raise SQL errors. A general-purpose ticket-edit endpoint and full return-authorization API are not implemented. Refund creation is mediated by finalization, not an unrestricted direct customer write.
