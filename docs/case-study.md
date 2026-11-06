# Portfolio case study — NovaCart Commerce

Built by Anupom Mojumder as a synthetic AI support operations demonstration.

## Problem
Support teams repeatedly inspect orders, interpret policies and coordinate refund decisions across separate systems. Untraceable AI answers and premature refund promises introduce risk.

## Engineering approach
Separated deterministic authority from AI interpretation: PostgreSQL owns customer/order matching, duplicate control, eligibility and approvals; n8n coordinates eight specialist roles; the dashboard exposes records behind staff authorization. Every refund remains simulated and every outbound response held.

## Demonstrated work
Created a fictional business knowledge pack and operational dataset; implemented isolated Supabase resources; saved modular n8n workflows using existing credentials; built a React/TypeScript/Tailwind operations UI; exercised database, access-control and failure paths against live services.

## Evidence and limitations
81 distinct automated checks passed, with 71 database checks repeated successfully. A real provider-credit failure exposed an error-handler expression defect, which was fixed and rerun. This demonstrates fault handling, not successful AI resolution. Model quality, semantic relevance, complete email-to-dashboard acceptance and production performance remain unmeasured. No invented ROI or automation-resolution rate is presented.

## Next milestone
Restore model availability, enroll staff, verify semantic retrieval and all eight model roles, complete delivery/retry adapters, run full channel journeys and obtain launch approval. See final-report.md for honest readiness status.
