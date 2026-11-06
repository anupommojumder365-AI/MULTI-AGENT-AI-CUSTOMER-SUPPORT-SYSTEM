# Support operating procedure

1. Intake: validate message length, channel identifier and synthetic customer domain. For Gmail, create an unverified review ticket; staff must verify identity through an approved process before running resolution.
2. Investigate: select the exact order, compare customer ownership, inspect carrier/tracking/status/promised date. Never infer delivery from a customer's wording.
3. Ground: retrieve current policy evidence; if retrieval or model service fails, preserve the ticket and escalate rather than fabricate a response.
4. Decide: lost parcels or undelivered parcels at least seven days beyond promise qualify for refund review. Earlier delays require investigation. Delivered returns require condition/eligibility review; inspection is manual.
5. Review: inspect verified facts, role outputs and QA flags. An approver may approve_simulated or reject; approval is a record only.
6. Communicate: responses remain held. Before any real send, independently confirm recipient, content, channel restrictions and explicit authorization. No sends occurred during implementation.
7. Recover: inspect error logs, restore provider availability, use bounded retry_case with the same ticket, and rerun acceptance. Avoid submitting new IDs merely to bypass deduplication.
8. Monitor: review error/escalation queues and hourly maintenance reports. Scheduler is saved inactive. Retain test evidence; cleanup requires explicit authorization.

Policy authority: policies.md (36 fictional entries). Human target: one business day during Monday–Friday 09:00–17:00 Europe/London; not a guaranteed SLA.
