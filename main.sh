#!/bin/bash
set -e

echo "AC_RESIGN_FILENAME:$AC_RESIGN_FILENAME"
echo "AC_RESIGN_FILE_URL:$AC_RESIGN_FILE_URL"

echo "AC_API_KEY:$AC_API_KEY"
echo "AC_API_KEY_FILE_NAME:$AC_API_KEY_FILE_NAME"
echo "AC_FASTFILE_CONFIG:$AC_FASTFILE_CONFIG"
echo "AC_CERTIFICATE_NAME:$AC_CERTIFICATE_NAME"
echo "AC_APP_IDENTIFIERS:$AC_APP_IDENTIFIERS"

curl -o "./$AC_RESIGN_FILENAME" -k "$AC_RESIGN_FILE_URL"

AC_PROVISION_PROFILE_PATHS="$AC_TEMP_DIR/fastlane-resign"
PROVISIONING_PROFILE_MAPS="$ProvisioningProfileMaps"

echo "PROVISIONING_PROFILE_MAPS:$PROVISIONING_PROFILE_MAPS"
echo "AC_PROVISIONING_PROFILES:$AC_PROVISIONING_PROFILES"
echo "AC_PROVISION_PROFILE_PATHS:$AC_PROVISION_PROFILE_PATHS"

if [[ -n "$PROVISIONING_PROFILE_MAPS" ]]; then
  mkdir -p "$AC_PROVISION_PROFILE_PATHS"

  echo "$PROVISIONING_PROFILE_MAPS" | jq -c '.[]' | while read -r entry; do
    bundle_id=$(echo "$entry" | jq -r '.BundleId')
    profile_base64=$(echo "$entry" | jq -r '.File')

    if [[ -n "$bundle_id" && -n "$profile_base64" ]]; then
      dest="$AC_PROVISION_PROFILE_PATHS/$bundle_id.mobileprovision"
      echo "Writing provision profile for: $bundle_id -> $dest"
      echo "$profile_base64" | base64 -d > "$dest"
    else
      echo "Missing bundle_id or file content for bundle $bundle_id in provisioning profile map. Skipping..."
    fi
  done
else
  echo "Pre-selected provision profiles are not found, provision profiles will be tried to download using App Store Connect services"
fi

IFS=' ' read -ra ALL_APP_IDENTIFIERS <<< "$AC_APP_IDENTIFIERS"

# Parse already handled bundleIds from ProvisioningProfileMaps
HANDLED_APP_IDENTIFIERS=()
if [[ -n "$PROVISIONING_PROFILE_MAPS" ]]; then
  while IFS= read -r id; do
    HANDLED_APP_IDENTIFIERS+=("$id")
  done < <(echo "$PROVISIONING_PROFILE_MAPS" | jq -r '.[].BundleId')
fi

# Calculate difference: items in ALL_APP_IDENTIFIERS but not in HANDLED_APP_IDENTIFIERS
AC_APP_IDENTIFIERS_TO_DOWNLOAD=""
for id in "${ALL_APP_IDENTIFIERS[@]}"; do
  skip=false
  for handled in "${HANDLED_APP_IDENTIFIERS[@]}"; do
    if [[ "$id" == "$handled" ]]; then
      skip=true
      break
    fi
  done
  if [[ "$skip" == false ]]; then
    AC_APP_IDENTIFIERS_TO_DOWNLOAD+="$id "
  fi
done

AC_APP_IDENTIFIERS_TO_DOWNLOAD=$(echo "$AC_APP_IDENTIFIERS_TO_DOWNLOAD" | xargs)

echo "AC_APP_IDENTIFIERS_TO_DOWNLOAD: $AC_APP_IDENTIFIERS_TO_DOWNLOAD"

bundle init
        echo "gem \"fastlane\"">>Gemfile
        bundle install
        mkdir fastlane
        touch fastlane/Appfile
        touch fastlane/Fastfile
        mv $AC_FASTFILE_CONFIG "fastlane/Fastfile"
        mv "$AC_API_KEY" "$AC_API_KEY_FILE_NAME"

if [[ -n "$AC_APP_IDENTIFIERS_TO_DOWNLOAD" ]]; then
  echo "Some app identifiers are not pre-selected, trying to download missing provision profiles via App Store Connect..."
  bundle exec fastlane prepare_signing \
    app_identifiers:"$AC_APP_IDENTIFIERS_TO_DOWNLOAD" \
    output_path:"$AC_PROVISION_PROFILE_PATHS"
else
  echo "✅ All provision profiles are pre-selected. Nothing will be downloaded from App Store Connect."
fi


bundle exec fastlane resign_release \
  app_identifiers:$AC_APP_IDENTIFIERS \
  provision_profiles_path:"$AC_PROVISION_PROFILE_PATHS" \
  ipa_file:"./$AC_RESIGN_FILENAME" \
  certificate_name:"$AC_CERTIFICATE_NAME" \
  output_dir:"$AC_OUTPUT_DIR" 

  mv "./$AC_RESIGN_FILENAME" "$AC_OUTPUT_DIR/"