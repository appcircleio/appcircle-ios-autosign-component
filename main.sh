#!/bin/bash

printenv | grep AC_

echo "AC_RESIGN_FILENAME:$AC_RESIGN_FILENAME"
echo "AC_RESIGN_FILE_URL:$AC_RESIGN_FILE_URL"

echo "AC_API_KEY:$AC_API_KEY"
echo "AC_API_KEY_FILE_NAME:$AC_API_KEY_FILE_NAME"
echo "AC_FASTFILE_CONFIG:$AC_FASTFILE_CONFIG"
echo "AC_CERTIFICATE_NAME:$AC_CERTIFICATE_NAME"
echo "AC_APP_IDENTIFIERS:$AC_APP_IDENTIFIERS"
echo "AC_PROVISIONING_PATHS:$AC_PROVISIONING_PATHS"

curl -o "./$AC_RESIGN_FILENAME" -k "$AC_RESIGN_FILE_URL"

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
  ipa_file:"./$AC_RESIGN_FILENAME" \
  certificate_name:"./$AC_CERTIFICATE_NAME" \
  output_dir:"$AC_OUTPUT_DIR" 