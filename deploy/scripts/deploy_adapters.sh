#!/usr/bin/env bash
set -euo pipefail

source .env

echo "Deploying UMA CTF Adapters..."
echo ""
echo "Deploy config:"
echo "  Admin:           $ADMIN"
echo "  CTF Core:        $CTF"
echo "  NegRisk Operator:$NEG_RISK_OPERATOR"
echo "  Finder:          $FINDER"
echo "  OptimisticOracle:$OPTIMISTIC_ORACLE"
echo "  RPC:             $RPC_URL"
echo ""

OUTPUT="$(forge script DeployAdapters \
    --private-key "$PK" \
    --rpc-url "$RPC_URL" \
    --json \
    --broadcast \
    --slow \
    --verify \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    -s "deployAdapters(address,address,address,address,address)" \
    "$ADMIN" "$CTF" "$NEG_RISK_OPERATOR" "$FINDER" "$OPTIMISTIC_ORACLE")"

STANDARD_ADAPTER=$(echo "$OUTPUT" | grep "{" | jq -r .returns.standardAdapter.value)
NEG_RISK_ADAPTER_ADDR=$(echo "$OUTPUT" | grep "{" | jq -r .returns.negRiskAdapter.value)

echo ""
echo "Deployed:"
echo "  Standard adapter: $STANDARD_ADAPTER"
echo "  NegRisk adapter:  $NEG_RISK_ADAPTER_ADDR"

echo "Complete!"
