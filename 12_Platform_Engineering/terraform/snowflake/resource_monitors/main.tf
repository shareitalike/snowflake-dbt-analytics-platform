# FinOps: Resource Monitors
# Automatically suspend warehouses if they exceed their monthly budget.

resource "snowflake_resource_monitor" "etl_monitor" {
  name         = "PROD_ETL_MONITOR"
  credit_quota = 100 # Enterprise Budget
  frequency    = "MONTHLY"
  start_timestamp = "IMMEDIATELY"

  notify_triggers            = [75, 90] # Sends alert at 75% and 90%
  suspend_triggers           = [100]    # Suspends execution exactly at 100%
  suspend_immediate_triggers = [110]    # Hard kills active queries at 110%
}

resource "snowflake_resource_monitor" "bi_monitor" {
  name         = "PROD_BI_MONITOR"
  credit_quota = 50
  frequency    = "MONTHLY"
  start_timestamp = "IMMEDIATELY"

  notify_triggers  = [80, 95]
  suspend_triggers = [100]
}
