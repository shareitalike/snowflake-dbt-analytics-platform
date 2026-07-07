{% docs gmv %}
**Gross Merchandise Value (GMV)**
The total dollar value of merchandise sold over a given period of time, *before* the deduction of any fees, discounts, or returns. 
- **Calculation:** `SUM(quantity * unit_price)`
- **Owner:** Finance
{% enddocs %}

{% docs net_revenue %}
**Net Revenue**
The true recognized revenue for the business. This is calculated after deducting discounts, refunds, and taxes from the GMV.
- **Calculation:** `SUM((quantity * unit_price) - discounts - taxes - refunds)`
- **Owner:** Finance
{% enddocs %}

{% docs cac %}
**Customer Acquisition Cost (CAC)**
The total sales and marketing cost required to earn a new customer over a specific time period.
- **Calculation:** `Total Marketing Spend / New Customers Acquired`
- **Owner:** Marketing
{% enddocs %}
