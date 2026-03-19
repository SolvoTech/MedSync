#!/usr/bin/env bash
set -euo pipefail

PROJECT_REF="${PROJECT_REF:-givfjbxoqtougorolymn}"
TEMPLATES_FILE="${TEMPLATES_FILE:-supabase/templates/auth_email_templates.json}"

if [[ -z "${SUPABASE_ACCESS_TOKEN:-}" ]]; then
  echo "SUPABASE_ACCESS_TOKEN is required."
  echo "Create one at: https://supabase.com/dashboard/account/tokens"
  exit 1
fi

if [[ ! -f "$TEMPLATES_FILE" ]]; then
  echo "Template file not found: $TEMPLATES_FILE"
  exit 1
fi

echo "Applying auth email templates to project: $PROJECT_REF"
patch_status="$(curl -sS -o /tmp/supabase_auth_template_patch_response.json -w "%{http_code}" -X PATCH "https://api.supabase.com/v1/projects/${PROJECT_REF}/config/auth" \
  -H "Authorization: Bearer ${SUPABASE_ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  --data-binary "@${TEMPLATES_FILE}")"

if [[ ! "$patch_status" =~ ^2 ]]; then
  echo "PATCH failed with HTTP $patch_status"
  echo "Response body:"
  cat /tmp/supabase_auth_template_patch_response.json
  exit 1
fi

echo "Patch request succeeded (HTTP $patch_status)."
echo "Response saved to /tmp/supabase_auth_template_patch_response.json"

echo "Fetching auth config summary..."
get_status="$(curl -sS -o /tmp/supabase_auth_template_current_config.json -w "%{http_code}" -X GET "https://api.supabase.com/v1/projects/${PROJECT_REF}/config/auth" \
  -H "Authorization: Bearer ${SUPABASE_ACCESS_TOKEN}")"

if [[ ! "$get_status" =~ ^2 ]]; then
  echo "GET config failed with HTTP $get_status"
  echo "Response body:"
  cat /tmp/supabase_auth_template_current_config.json
  exit 1
fi

echo "Current config saved to /tmp/supabase_auth_template_current_config.json"
if ! grep -q '"mailer_subjects_confirmation"' /tmp/supabase_auth_template_current_config.json; then
  echo "Warning: mailer fields were not found in the returned config."
  echo "Please review /tmp/supabase_auth_template_current_config.json"
  exit 1
fi

if grep -q '"site_url"[[:space:]]*:[[:space:]]*"http://localhost:3000"' /tmp/supabase_auth_template_current_config.json; then
  echo "site_url is still http://localhost:3000."
  echo "Please ensure payload includes a non-localhost site_url and rerun."
  exit 1
fi

echo "Done."
