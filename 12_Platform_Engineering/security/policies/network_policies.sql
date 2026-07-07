/* ==============================================================================
 * FILE: network_policies.sql
 * PHASE: 12 - Platform Engineering
 * 
 * EXPLANATION: Enforces Zero Trust network security by defining IP allow-lists and block-lists for accessing the Snowflake account.
 * DESIGN DECISIONS: The Master Network Policy explicitly allows only the Corporate VPN and the AWS NAT Gateway (for Airflow), while blocking all other traffic (0.0.0.0/0).
 * WHY: Even if an attacker steals a username and password (or private key), they cannot access Snowflake unless they are physically on the corporate VPN or operating from the authorized AWS VPC.
 * ============================================================================== */

USE ROLE SECURITYADMIN;

-- 1. Create a Master Network Policy limiting access to the corporate VPN and AWS NAT Gateways
CREATE OR REPLACE NETWORK POLICY ENTERPRISE_MASTER_POLICY
  ALLOWED_IP_LIST = (
    '192.168.1.0/24', -- Corporate VPN
    '203.0.113.50/32' -- AWS MWAA NAT Gateway (Airflow)
  )
  BLOCKED_IP_LIST = (
    '0.0.0.0/0'       -- Block all other traffic implicitly (Zero Trust)
  )
  COMMENT = 'Master Network Policy for OmniRetail restricting access to corporate network and authorized AWS VPCs.';

-- 2. Apply Master Policy to the entire Account
ALTER ACCOUNT SET NETWORK_POLICY = ENTERPRISE_MASTER_POLICY;

-- 3. Dedicated strict policy for Service Accounts (e.g., dbt Cloud IP range only)
CREATE OR REPLACE NETWORK POLICY SERVICE_ACCOUNT_POLICY
  ALLOWED_IP_LIST = ('52.23.14.9/32') -- Example dbt Cloud US-East IP
  COMMENT = 'Strict IP allowlist for automated Service Accounts';
