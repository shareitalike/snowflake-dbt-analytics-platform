/* ==============================================================================
 * FILE: 07_monitoring_tests.sql
 * PHASE: 08 - CDC Framework
 * 
 * EXPLANATION: Unit tests for the custom SLA evaluation and Alerting framework.
 * DESIGN DECISIONS: Artificially alters a Watermark to simulate a 2-day delay, triggering an SLA breach. Runs the evaluation procedure twice to prove the deduplication logic prevents spamming the Alert Queue.
 * WHY: If the monitoring system fails, silent data outages occur. Proving that alerts are correctly triggered and deduplicated ensures the Data Engineering team is reliably notified of failures without being overwhelmed.
 * ============================================================================== */

USE ROLE DATA_ENGINEER;

-- ==========================================
-- TEST CASE 1: SLA Breach Alert Generation
-- ==========================================
-- Setup: Forge a Watermark that is extremely old to force an SLA breach
UPDATE DB_PROD_METADATA.SC_META_CONTROL.TB_WATERMARK 
SET High_Watermark = DATEADD('day', -2, CURRENT_TIMESTAMP()) 
WHERE Pipeline_ID = 'PIPE_TEST';

-- Execute the Evaluation Procedure
CALL DB_PROD_METADATA.SC_META_OBSERVABILITY.SP_EVALUATE_SLA_BREACHES();

-- Validation: The TB_ALERT_QUEUE should now contain a CRITICAL alert.
SELECT Alert_Type, Severity, Alert_Message 
FROM DB_PROD_METADATA.SC_META_OBSERVABILITY.TB_ALERT_QUEUE 
WHERE Pipeline_ID = 'PIPE_TEST' AND Is_Resolved = FALSE;

-- ==========================================
-- TEST CASE 2: Alert Deduplication (Spam Prevention)
-- ==========================================
-- Execute the Evaluation Procedure again without fixing the underlying watermark issue
CALL DB_PROD_METADATA.SC_META_OBSERVABILITY.SP_EVALUATE_SLA_BREACHES();

-- Validation: There should still only be exactly 1 unresolved alert for PIPE_TEST.
SELECT COUNT(*) 
FROM DB_PROD_METADATA.SC_META_OBSERVABILITY.TB_ALERT_QUEUE 
WHERE Pipeline_ID = 'PIPE_TEST' AND Is_Resolved = FALSE;
-- Expected Count: 1

-- ==========================================
-- ROLLBACK SCRIPTS (Clean up test data)
-- ==========================================
-- Resolve the alert manually
UPDATE DB_PROD_METADATA.SC_META_OBSERVABILITY.TB_ALERT_QUEUE 
SET Is_Resolved = TRUE, Resolved_At = CURRENT_TIMESTAMP() 
WHERE Pipeline_ID = 'PIPE_TEST';
