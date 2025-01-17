# ============================================
# Scriptnaam: Disable-SelfServicePurchase.ps1
# Beschrijving: Dit script schakelt de zelfbedieningsaankoop uit voor alle producten
#               met de opgegeven beleids-ID.
# Auteur: Fabio van der Burg
# Datum: 17-01-2025
# Versie: 1.0
# ============================================

# Haal alle product-ID's op met het opgegeven beleid 
$productPolicies = Get-MSCommerceProductPolicies -PolicyID AllowSelfServicePurchase

# Loop door ieder product ID and disable self-service purchase
foreach ($policy in $productPolicies) {
    Update-MSCommerceProductPolicy -PolicyId AllowSelfServicePurchase -Productid $policy.ProductId -Enabled $false
}
