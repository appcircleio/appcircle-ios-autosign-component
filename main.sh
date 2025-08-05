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
PROVISIONING_PROFILE_MAPS="${ProvisioningProfileMaps}"

if [[ -n "$AC_PROVISIONING_PROFILES" && -n "$PROVISIONING_PROFILE_MAPS"]]; then
  mkdir -p "$AC_PROVISION_PROFILE_PATHS"

  IFS='|' read -ra PROFILES <<< "$AC_PROVISIONING_PROFILES"

  echo "$PROVISIONING_PROFILE_MAPS" | jq -c '.[]' | while read -r entry; do
    bundle_id=$(echo "$entry" | jq -r '.bundleId')
    profile_id=$(echo "$entry" | jq -r '.provisioningProfileId')

    for profile_path in "${PROFILES[@]}"; do
      filename=$(basename "$profile_path")

      if [[ "$filename" == *"$profile_id"* ]]; then
        dest="$AC_PROVISION_PROFILE_PATHS/$bundle_id.mobileprovision"
        echo "Using provided (pre-selected) provision profile for: $bundle_id"
        echo "Copying $profile_path -> $dest"
        cp "$profile_path" "$dest"
      fi
    done
  done
else
  echo "Pre-selected provision profiles are not found, provision profiles will be tried to download using App Store Connect services"
fi

bundle init
        echo "gem \"fastlane\"">>Gemfile
        bundle install
        mkdir fastlane
        touch fastlane/Appfile
        touch fastlane/Fastfile
        mv $AC_FASTFILE_CONFIG "fastlane/Fastfile"
        mv "$AC_API_KEY" "$AC_API_KEY_FILE_NAME"

bundle exec fastlane prepare_signing \
  app_identifiers:$AC_APP_IDENTIFIERS \
  output_path:"$AC_PROVISION_PROFILE_PATHS"

bundle exec fastlane resign_release \
  app_identifiers:$AC_APP_IDENTIFIERS \
  provision_profiles_path:"$AC_PROVISION_PROFILE_PATHS" \
  ipa_file:"./$AC_RESIGN_FILENAME" \
  certificate_name:"$AC_CERTIFICATE_NAME" \
  output_dir:"$AC_OUTPUT_DIR" 

  mv "./$AC_RESIGN_FILENAME" "$AC_OUTPUT_DIR/"