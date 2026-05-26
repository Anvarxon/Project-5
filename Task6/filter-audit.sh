#!/usr/bin/env bash
set -euo pipefail

INPUT="${1:-/var/log/audit.log}"
OUTPUT="${2:-audit-extract.json}"

if [[ ! -f "$INPUT" ]]; then
  echo "Audit log not found: $INPUT" >&2
  exit 1
fi

# Kubernetes audit.log is a stream of JSON audit events, one JSON object per line.
jq -s '
  [
    .[]
    | select(
        (.verb == "get" and .objectRef.resource == "secrets")
        or
        (.verb == "create" and .objectRef.resource == "pods"
          and any(.requestObject.spec.containers[]?; .securityContext.privileged == true))
        or
        (.verb == "create" and .objectRef.resource == "pods"
          and .objectRef.subresource == "exec")
        or
        (.verb == "create" and .objectRef.resource == "rolebindings"
          and .requestObject.roleRef.name == "cluster-admin")
        or
        ((.requestURI // "") | test("audit-policy"; "i"))
        or
        ((.objectRef.name // "") | test("audit-policy"; "i"))
      )
  ]
' "$INPUT" > "$OUTPUT"

echo "Suspicious audit events saved to $OUTPUT"
