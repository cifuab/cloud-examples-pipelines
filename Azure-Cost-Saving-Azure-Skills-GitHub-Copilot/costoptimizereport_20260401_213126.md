# Azure Cost Optimization Report
**Generated**: 2026-04-01T20:29:00Z  
**Subscription**: thomasthorntoncloud (`04109105-f3ca-44ac-a3a7-66b4936112c3`)  
**Analysis Period**: 2026-03-02 → 2026-04-01 (30 days)  
**Currency**: GBP (£)

---

## Executive Summary

| Metric | Value |
|--------|-------|
| 💰 Total Monthly Cost | **£57.67** |
| 🗑️ Immediate Orphaned Savings | **£2.72/month** |
| 📉 Potential Optimisation Savings | **£35.70/month** (if APIM deleted) |
| 📅 Annualised Potential Savings | **up to £461/year** |

**Top 3 Cost Drivers:**
1. 🔴 [APIM `apim-test-federeated`](https://portal.azure.com/#@8d1b0a04-ae70-4b0a-b26a-8ad9fdd7807e/resource/subscriptions/04109105-f3ca-44ac-a3a7-66b4936112c3/resourceGroups/apim-test-federated/providers/Microsoft.ApiManagement/service/apim-test-federeated/overview) — **£35.70/month** (62% of total spend)
2. 🟡 GitHub Enterprise Account — **£14.51/month** (25% of total spend)
3. 🟡 [ACR `tamopsgithubacr`](https://portal.azure.com/#@8d1b0a04-ae70-4b0a-b26a-8ad9fdd7807e/resource/subscriptions/04109105-f3ca-44ac-a3a7-66b4936112c3/resourceGroups/tamopsgithubacr-rg/providers/Microsoft.ContainerRegistry/registries/tamopsgithubacr/overview) — **£3.76/month** (7% of total spend)

---

## Cost Breakdown (Last 30 Days)

| Rank | Resource | Type | Resource Group | Cost (GBP) | % of Total |
|------|----------|------|----------------|-----------|------------|
| 1 | apim-test-federeated | API Management | apim-test-federated | £35.70 | 61.9% |
| 2 | GitHub Enterprise | github/enterpriseaccount | *(subscription-level)* | £14.51 | 25.2% |
| 3 | tamopsgithubacr | Container Registry | tamopsgithubacr-rg | £3.76 | 6.5% |
| 4 | appgw-pip ⚠️ **ORPHANED** | Public IP | tamopsaca-rg | £2.72 | 4.7% |
| 5 | ai-foundry-thomas | Cognitive Services | ai-foundry | £1.21 | 2.1% |
| 6 | tamopscontent | Cognitive Services | tamops-openai | £0.24 | 0.4% |
| 7 | thoma-medvez99-eastus2 | Cognitive Services | ai-foundry | £0.07 | 0.1% |
| 8 | homeassistantbkup | Storage | homeassistant | £0.05 | <0.1% |
| 9 | tamopslogicapp1 | Logic Apps | tamops-logicapps-rg | £0.003 | <0.1% |
| 10 | *(Databricks, other storage)* | Various | Various | ~£0.00 | ~0% |
| | **TOTAL** | | | **£57.67** | 100% |

---

## Orphaned Resources — Immediate Savings 🗑️

### ⚠️ Orphaned Static Public IP: `appgw-pip`

| Property | Value |
|----------|-------|
| Resource Group | `tamopsaca-rg` |
| IP Address | `20.254.116.80` |
| Allocation | Static |
| Associated With | **None (unattached)** |
| 💰 ACTUAL Monthly Cost | **£2.72/month** |
| 📊 ESTIMATED Annual Savings | **~£32.64/year** |
| [Azure Portal Link](https://portal.azure.com/#@8d1b0a04-ae70-4b0a-b26a-8ad9fdd7807e/resource/subscriptions/04109105-f3ca-44ac-a3a7-66b4936112c3/resourceGroups/tamopsaca-rg/providers/Microsoft.Network/publicIPAddresses/appgw-pip/overview) | |

**Finding**: No Application Gateway or Network Interface exists in `tamopsaca-rg`. This Static Public IP is unattached and accruing charges with no purpose. Azure charges for Static IPs whether they are in use or not.

**⚠️ Deletion Command (requires approval):**
```bash
# Verify it is truly unattached before deleting
az network public-ip show --resource-group tamopsaca-rg --name appgw-pip \
  --query "ipConfiguration" -o tsv

# If output is empty/null, safe to delete:
az network public-ip delete --resource-group tamopsaca-rg --name appgw-pip
```

---

## Optimisation Recommendations

### Priority 1 — High Impact: Review APIM Instance 🔴

| Property | Value |
|----------|-------|
| Resource | `apim-test-federeated` |
| Resource Group | `apim-test-federated` |
| SKU | **Developer** (not production SLA) |
| Created | October 2025 |
| 💰 ACTUAL Monthly Cost | **£35.70/month** |
| 📊 ESTIMATED Annual Cost | **~£428/year** |
| [Azure Portal Link](https://portal.azure.com/#@8d1b0a04-ae70-4b0a-b26a-8ad9fdd7807e/resource/subscriptions/04109105-f3ca-44ac-a3a7-66b4936112c3/resourceGroups/apim-test-federated/providers/Microsoft.ApiManagement/service/apim-test-federeated/overview) | |

**Finding**: The Developer tier is the **lowest-cost APIM tier** (~£35/month), but it carries no SLA and is intended for dev/test use only. This instance was created in October 2025 and appears to be a test environment given the resource group naming. 

**Options:**
1. **Delete if no longer needed** — saves £35.70/month (£428/year)
2. **Keep if actively used** — Developer tier is already the minimum viable APIM SKU
3. **Export APIs before deleting** (if needed later):
   ```bash
   # Export APIs before deletion
   az apim api list --resource-group apim-test-federated \
     --service-name apim-test-federeated --query "[].name" -o tsv
   
   # Delete APIM (⚠️ irreversible - get approval first)
   az apim delete --resource-group apim-test-federated \
     --name apim-test-federeated --yes
   ```

---

### Priority 2 — Medium Impact: ACR Usage Review 🟡

| Property | Value |
|----------|-------|
| Resource | `tamopsgithubacr` |
| Resource Group | `tamopsgithubacr-rg` |
| SKU | Basic (already cheapest tier) |
| Created | December 2023 |
| 💰 ACTUAL Monthly Cost | **£3.76/month** |
| [Azure Portal Link](https://portal.azure.com/#@8d1b0a04-ae70-4b0a-b26a-8ad9fdd7807e/resource/subscriptions/04109105-f3ca-44ac-a3a7-66b4936112c3/resourceGroups/tamopsgithubacr-rg/providers/Microsoft.ContainerRegistry/registries/tamopsgithubacr/overview) | |

**Finding**: Already on the Basic tier (cheapest available). Main opportunity is to delete if unused:
```bash
# Check when images were last pushed/pulled
az acr repository list --name tamopsgithubacr -o tsv
az acr show-usage --resource-group tamopsgithubacr-rg --name tamopsgithubacr

# If unused, delete to save £3.76/month:
az acr delete --resource-group tamopsgithubacr-rg --name tamopsgithubacr --yes
```

---

### Priority 3 — Review Unused Resource Groups 🟡

The following resource groups exist with **near-zero cost** but contain resources that may be orphaned lab/test environments. Review and clean up to reduce management overhead:

| Resource Group | Notes |
|----------------|-------|
| `devops-journey-rg` | Lab environment |
| `devops-journey-rg-may2024` | Old lab (May 2024) — likely deletable |
| `devops-journey-rg-oct2024` | Old lab (Oct 2024) — likely deletable |
| `devopshardway-rg` | Lab environment |
| `deploy-first-containerapp-rg` | Container App lab |
| `tamops-certtest` | Certificate test — likely temporary |
| `tamops-rhel-els` | RHEL ELS test |
| `ai-poc-karthik` | POC environment |
| Multiple `databricks-rg-*` managed RGs | Auto-created by Databricks — safe to ignore if workspaces exist |

```bash
# Check resources in old lab RGs before deleting
az resource list --resource-group devops-journey-rg-may2024 --query "[].{name:name,type:type}" -o table
az resource list --resource-group devops-journey-rg-oct2024 --query "[].{name:name,type:type}" -o table

# Delete old resource groups (⚠️ irreversible):
az group delete --name devops-journey-rg-may2024 --yes --no-wait
az group delete --name devops-journey-rg-oct2024 --yes --no-wait
```

---

### Priority 4 — Long-Term: Tagging & Cost Governance 🔵

**Finding from azqr**: Resources across the subscription lack consistent cost allocation tags. This makes it harder to track spend by project/owner.

```bash
# Apply cost tags to key resources
az resource tag --ids \
  "/subscriptions/04109105-f3ca-44ac-a3a7-66b4936112c3/resourceGroups/apim-test-federated/providers/Microsoft.ApiManagement/service/apim-test-federeated" \
  --tags environment=test project=api-management owner=thomasthornton

# Set a budget alert (e.g., warn at £60/month)
az consumption budget create \
  --budget-name "monthly-spend-alert" \
  --amount 60 \
  --time-grain Monthly \
  --start-date $(date +%Y-%m-01) \
  --end-date 2027-01-01 \
  --subscription 04109105-f3ca-44ac-a3a7-66b4936112c3
```

---

## Total Estimated Savings Summary

| Action | Monthly Saving | Annual Saving | Risk |
|--------|----------------|---------------|------|
| Delete orphaned `appgw-pip` | **£2.72** | **£32.64** | 🟢 Low — confirmed orphaned |
| Delete `apim-test-federeated` | **£35.70** | **£428.40** | 🟡 Medium — verify not in use |
| Delete `tamopsgithubacr` (if unused) | **£3.76** | **£45.12** | 🟡 Medium — verify not used by CI/CD |
| Delete old lab resource groups | ~£0 | ~£0 | 🟢 Low — review contents first |
| **Total if all actioned** | **~£42.18** | **~£506/year** | |

---

## azqr Scan Summary

Full scan results saved in: `output/azqr-report.xlsx`

Key findings from azqr scan (51 resources scanned):
- ⚠️ Multiple storage accounts missing diagnostic settings
- ⚠️ Key Vault API versions approaching retirement (upgrade recommended)
- ⚠️ Storage accounts still support TLS 1.0/1.1 (security risk, not cost)
- ℹ️ No Defender for Cloud enabled (cost consideration if enabling)

---

## Validation Appendix

### Data Sources
| Source | File | Notes |
|--------|------|-------|
| Azure Cost Management API | `output/cost-query-result_20260401_212931.json` | ActualCost, 30-day window |
| Azure Quick Review (azqr) | `output/azqr-report.xlsx` | Full compliance scan |
| Azure Advisor | *(queried live)* | HighAvailability recommendations only (no Cost recommendations active) |

### Data Classification
- 💰 **ACTUAL DATA** — Retrieved from Azure Cost Management API
- 📊 **ESTIMATED SAVINGS** — Calculated from actual cost data
- ⚠️ All destructive operations require explicit user approval before execution

