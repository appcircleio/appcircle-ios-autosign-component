#!/bin/bash

printenv | grep AC_

echo "IPAFileName:$AC_APP_FILE_NAME"
echo "IPAFileUrl:$AC_RESIGN_FILE_URL"

echo "AppStoreConnectApiKey:$AC_API_KEY"
echo "AppStoreConnectApiKeyFileName:$AC_API_KEY_FILE_NAME"
echo "AC_FASTFILE_CONFIG:$AC_FASTFILE_CONFIG"
echo "AC_CERTIFICATE_NAME:$AC_CERTIFICATE_NAME"

curl -o "./$AC_APP_FILE_NAME" -k "$AC_RESIGN_FILE_URL"

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
  output_path:"$AC_TEMP_DIR/fastlane-resign"

fastlane resign_release \
  provisioning_profile_mapping:$AC_PROVISIONING_PATHS \
  ipa_file:"./$AC_APP_FILE_NAME" \
  certificate_name:"./$AC_CERTIFICATE_NAME" \
  output_dir:"$AC_OUTPUT_DIR" 