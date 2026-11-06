# Business requirements v1

NovaCart Commerce is a fictional UK retailer selling laptops, electronics and home accessories in GBP. The demo supports 100 synthetic customers, 200 orders and 10 products. Its operators need traceable resolution of delayed delivery, lost parcels, return enquiries, refund requests and complaints.

## Actors and permissions
Customers submit messages through a trusted intake boundary. Staff viewers may inspect support records. Approvers may approve or reject simulated refunds; administrators manage staff membership outside the browser. Service credentials execute narrowly scoped workflow database functions. Unverified email senders receive no order facts.

## Functional acceptance
1. Validate bounded input and reject unsupported identities or malformed messages.
2. Deduplicate using the channel external identifier and lock concurrent submissions.
3. Match customer and order ownership before context disclosure.
4. Retrieve shipping facts from orders and policy evidence from pgvector retrieval.
5. Run eight role contracts and retain outputs, model identity and execution history.
6. Recompute refund eligibility in SQL regardless of model recommendation.
7. Create a single pending request per order; require human approval; never transfer money.
8. Hold outbound messages; expose operational queues only after staff authentication.
9. Preserve failure evidence, bounded retries and escalation when providers fail.
10. Present tickets, agents, customers, orders, refunds, escalations, policies, tests, logs, errors and analytics using backend data.

## Operational targets, not measured results
Target review within one business day; target 99% duplicate suppression and zero unauthorized disclosures. No latency, ROI, cost or production availability claim has been measured. Auditability and safe failure take priority over automated closure.

## Scope limits
No inventory synchronization, payment processor, carrier API or production customer onboarding. Shipping records are synthetic operational facts. Delivered-return policy is documented but a complete inspection/return-authorization subsystem is not implemented. Full scheduled customer follow-up delivery remains pending.
