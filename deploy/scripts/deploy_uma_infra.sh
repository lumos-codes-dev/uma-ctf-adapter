#!/usr/bin/env bash
set -euo pipefail

source .env

echo "Deploying UMA Infrastructure..."
echo ""
echo "Deploy config:"
echo "  Collateral: $COLLATERAL"
echo "  RPC:        $RPC_URL"
echo ""

OUTPUT="$(forge script DeployUmaInfra \
    --private-key "$PK" \
    --rpc-url "$RPC_URL" \
    --json \
    --broadcast \
    --slow \
    -s "deployUmaInfra(address)" "$COLLATERAL")"

FINDER=$(echo "$OUTPUT"       | grep "{" | jq -r .returns.finder.value)
OPTIMISTIC_ORACLE=$(echo "$OUTPUT" | grep "{" | jq -r .returns.optimisticOracle.value)

echo ""
echo "Deployed:"
echo "  Finder:           $FINDER"
echo "  OptimisticOracle: $OPTIMISTIC_ORACLE"

# Patch .env in place so subsequent scripts can pick up the values
if grep -q "^FINDER=" .env; then
    sed -i "s|^FINDER=.*|FINDER=$FINDER|" .env
else
    echo "FINDER=$FINDER" >> .env
fi

if grep -q "^OPTIMISTIC_ORACLE=" .env; then
    sed -i "s|^OPTIMISTIC_ORACLE=.*|OPTIMISTIC_ORACLE=$OPTIMISTIC_ORACLE|" .env
else
    echo "OPTIMISTIC_ORACLE=$OPTIMISTIC_ORACLE" >> .env
fi

echo ""
echo ".env updated with FINDER and OPTIMISTIC_ORACLE."
echo "Complete!"
