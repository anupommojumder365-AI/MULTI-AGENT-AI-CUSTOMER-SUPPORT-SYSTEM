# Setup and continuation runbook

## Existing deployed resources
Use evidence/resource-inventory.json for exact project/workflow IDs. All 15 n8n workflows are inactive. Existing credentials are referenced by ID in exports, never by secret value.

## Local application
`npm ci`, `npm run build`, `npm run dev`. src/main.tsx contains only the public Supabase URL/key, with staff authentication and RLS. The development preview uses port 4173 when started with the preview helper; standard Vite uses its configured defaults.

## Staff enrollment
Create/invite a staff identity through the authorized Supabase Auth administration UI, obtain its actual UUID, then insert that UUID into novacart_members with viewer, approver or admin role. Do not use a synthetic customer email as a real recipient. No persistent staff account was enrolled in this implementation; authenticated browser interactions remain unverified.

## Recreate database
Review and apply database SQL in numeric order to an isolated project. 001–008 contain schema, seed, RPCs, embeddings, operations, private approval hardening, email intake and historical demonstration support records. The SQL is a migration sequence, not a repeatedly idempotent installer. Existing applied migrations must not be rerun blindly.
Acceptance order timestamps were adjusted on the live database relative to execution time; use a fresh synthetic case with order age 10 days and promise age 7 days for reproducible acceptance boundaries.

## Unblock and verify
1. Restore billing/credit on the existing OpenAI credential or configure an authorized compatible model and embedding provider.
2. Execute Knowledge Indexing and verify all 36 embeddings, dimensions and retrieval relevance.
3. Enroll staff; test authenticated dashboard and role-specific refund buttons.
4. Run Acceptance Scenario with a new external ID or properly retry the failed case. Inspect all eight actual model outputs and policy citations.
5. Implement/configure approved Slack destination and Gmail delivery adapters. Existing outbox is held, not delivered. Scheduled customer follow-ups are still pending.
6. Repeat other major cases: unknown customer, wrong owner, early delay, confirmed lost, delivered return, disputed refund, provider outage and duplicate/concurrent request.
7. Create a dedicated GitHub repository with an available write-capable connection and push the source. No repository-creation action was exposed in this session.
8. Only after explicit production approval, unpause Vercel and enable intended triggers. Verify deployed auth and backend access before calling it live.

## Tests
Execute tests/database_suite.sql through the authorized SQL tool in the isolated demo database. It records db-suite-v1. database_regression.sql records v2. rls.sql exercises real authenticated SQL role/RLS boundaries with transient identities rolled back after each case. These do not substitute for browser Auth or complete n8n tests.
