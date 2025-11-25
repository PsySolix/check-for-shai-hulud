#!/bin/bash

set -e

# Parse command line arguments
NO_VERSION_CHECK=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --no-version-check)
      NO_VERSION_CHECK=true
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [OPTIONS]"
      echo "Check for compromised npm packages in your project and globally."
      echo ""
      echo "Options:"
      echo "  --no-version-check    Check if package exists (any version) instead of exact version"
      echo "  -h, --help           Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Use --help for usage information."
      exit 1
      ;;
  esac
done

# List of vulnerable package@versions (updated from Endor Labs, Socket.dev articles, and Mend.io MSC Customer Reference Sheet on Shai-Hulud attack)
VULNS=(
  "@ahmedhfarag/ngx-perfect-scrollbar@20.0.20"
  "@ahmedhfarag/ngx-virtual-scroller@4.0.4"
  "@art-ws/common@2.0.28"
  "@art-ws/config-eslint@2.0.4"
  "@art-ws/config-eslint@2.0.5"
  "@art-ws/config-ts@2.0.7"
  "@art-ws/config-ts@2.0.8"
  "@art-ws/db-context@2.0.24"
  "@art-ws/di@2.0.28"
  "@art-ws/di@2.0.32"
  "@art-ws/di-node@2.0.13"
  "@art-ws/eslint@1.0.5"
  "@art-ws/eslint@1.0.6"
  "@art-ws/fastify-http-server@2.0.24"
  "@art-ws/fastify-http-server@2.0.27"
  "@art-ws/http-server@2.0.21"
  "@art-ws/http-server@2.0.25"
  "@art-ws/openapi@0.1.9"
  "@art-ws/openapi@0.1.12"
  "@art-ws/package-base@1.0.5"
  "@art-ws/package-base@1.0.6"
  "@art-ws/prettier@1.0.5"
  "@art-ws/prettier@1.0.6"
  "@art-ws/slf@2.0.15"
  "@art-ws/slf@2.0.22"
  "@art-ws/ssl-info@1.0.9"
  "@art-ws/ssl-info@1.0.10"
  "@art-ws/web-app@1.0.3"
  "@art-ws/web-app@1.0.4"
  "@crowdstrike/commitlint@8.1.1"
  "@crowdstrike/commitlint@8.1.2"
  "@crowdstrike/falcon-shoelace@0.4.1"
  "@crowdstrike/falcon-shoelace@0.4.2"
  "@crowdstrike/foundry-js@0.19.1"
  "@crowdstrike/foundry-js@0.19.2"
  "@crowdstrike/glide-core@0.34.2"
  "@crowdstrike/glide-core@0.34.3"
  "@crowdstrike/logscale-dashboard@1.205.1"
  "@crowdstrike/logscale-dashboard@1.205.2"
  "@crowdstrike/logscale-file-editor@1.205.1"
  "@crowdstrike/logscale-file-editor@1.205.2"
  "@crowdstrike/logscale-parser-edit@1.205.1"
  "@crowdstrike/logscale-parser-edit@1.205.2"
  "@crowdstrike/logscale-search@1.205.1"
  "@crowdstrike/logscale-search@1.205.2"
  "@crowdstrike/tailwind-toucan-base@5.0.1"
  "@crowdstrike/tailwind-toucan-base@5.0.2"
  "@ctrl/deluge@7.2.1"
  "@ctrl/deluge@7.2.2"
  "@ctrl/golang-template@1.4.2"
  "@ctrl/golang-template@1.4.3"
  "@ctrl/magnet-link@4.0.3"
  "@ctrl/magnet-link@4.0.4"
  "@ctrl/ngx-codemirror@7.0.1"
  "@ctrl/ngx-codemirror@7.0.2"
  "@ctrl/ngx-csv@6.0.1"
  "@ctrl/ngx-csv@6.0.2"
  "@ctrl/ngx-emoji-mart@9.2.1"
  "@ctrl/ngx-emoji-mart@9.2.2"
  "@ctrl/ngx-rightclick@4.0.1"
  "@ctrl/ngx-rightclick@4.0.2"
  "@ctrl/qbittorrent@9.7.1"
  "@ctrl/qbittorrent@9.7.2"
  "@ctrl/react-adsense@2.0.1"
  "@ctrl/react-adsense@2.0.2"
  "@ctrl/shared-torrent@6.3.1"
  "@ctrl/shared-torrent@6.3.2"
  "@ctrl/tinycolor@4.1.1"
  "@ctrl/tinycolor@4.1.2"
  "@ctrl/torrent-file@4.1.1"
  "@ctrl/torrent-file@4.1.2"
  "@ctrl/transmission@7.3.1"
  "@ctrl/ts-base32@4.0.1"
  "@ctrl/ts-base32@4.0.2"
  "@hestjs/core@0.2.1"
  "@hestjs/cqrs@0.1.6"
  "@hestjs/demo@0.1.2"
  "@hestjs/eslint-config@0.1.2"
  "@hestjs/logger@0.1.6"
  "@hestjs/scalar@0.1.7"
  "@hestjs/validation@0.1.6"
  "@nativescript-community/arraybuffers@1.1.6"
  "@nativescript-community/arraybuffers@1.1.7"
  "@nativescript-community/arraybuffers@1.1.8"
  "@nativescript-community/gesturehandler@2.0.35"
  "@nativescript-community/perms@3.0.5"
  "@nativescript-community/perms@3.0.6"
  "@nativescript-community/perms@3.0.7"
  "@nativescript-community/perms@3.0.8"
  "@nativescript-community/sqlite@3.5.2"
  "@nativescript-community/sqlite@3.5.3"
  "@nativescript-community/sqlite@3.5.4"
  "@nativescript-community/sqlite@3.5.5"
  "@nativescript-community/text@1.6.9"
  "@nativescript-community/text@1.6.10"
  "@nativescript-community/text@1.6.11"
  "@nativescript-community/text@1.6.12"
  "@nativescript-community/typeorm@0.2.30"
  "@nativescript-community/typeorm@0.2.31"
  "@nativescript-community/typeorm@0.2.32"
  "@nativescript-community/typeorm@0.2.33"
  "@nativescript-community/ui-collectionview@6.0.6"
  "@nativescript-community/ui-document-picker@1.1.27"
  "@nativescript-community/ui-document-picker@1.1.28"
  "@nativescript-community/ui-drawer@0.1.30"
  "@nativescript-community/ui-image@4.5.6"
  "@nativescript-community/ui-label@1.3.35"
  "@nativescript-community/ui-label@1.3.36"
  "@nativescript-community/ui-label@1.3.37"
  "@nativescript-community/ui-material-bottom-navigation@7.2.72"
  "@nativescript-community/ui-material-bottom-navigation@7.2.73"
  "@nativescript-community/ui-material-bottom-navigation@7.2.74"
  "@nativescript-community/ui-material-bottom-navigation@7.2.75"
  "@nativescript-community/ui-material-bottomsheet@7.2.72"
  "@nativescript-community/ui-material-core@7.2.72"
  "@nativescript-community/ui-material-core@7.2.73"
  "@nativescript-community/ui-material-core@7.2.74"
  "@nativescript-community/ui-material-core@7.2.75"
  "@nativescript-community/ui-material-core-tabs@7.2.72"
  "@nativescript-community/ui-material-core-tabs@7.2.73"
  "@nativescript-community/ui-material-core-tabs@7.2.74"
  "@nativescript-community/ui-material-core-tabs@7.2.75"
  "@nativescript-community/ui-material-ripple@7.2.72"
  "@nativescript-community/ui-material-ripple@7.2.73"
  "@nativescript-community/ui-material-ripple@7.2.74"
  "@nativescript-community/ui-material-ripple@7.2.75"
  "@nativescript-community/ui-material-tabs@7.2.72"
  "@nativescript-community/ui-material-tabs@7.2.73"
  "@nativescript-community/ui-material-tabs@7.2.74"
  "@nativescript-community/ui-material-tabs@7.2.75"
  "@nativescript-community/ui-pager@14.1.36"
  "@nativescript-community/ui-pager@14.1.37"
  "@nativescript-community/ui-pager@14.1.38"
  "@nativescript-community/ui-pulltorefresh@2.5.4"
  "@nativescript-community/ui-pulltorefresh@2.5.5"
  "@nativescript-community/ui-pulltorefresh@2.5.6"
  "@nativescript-community/ui-pulltorefresh@2.5.7"
  "@nexe/config-manager@0.1.1"
  "@nexe/eslint-config@0.1.1"
  "@nexe/logger@0.1.3"
  "@nstudio/angular@20.0.4"
  "@nstudio/angular@20.0.5"
  "@nstudio/angular@20.0.6"
  "@nstudio/focus@20.0.4"
  "@nstudio/focus@20.0.5"
  "@nstudio/focus@20.0.6"
  "@nstudio/nativescript-checkbox@2.0.6"
  "@nstudio/nativescript-checkbox@2.0.7"
  "@nstudio/nativescript-checkbox@2.0.8"
  "@nstudio/nativescript-loading-indicator@5.0.1"
  "@nstudio/nativescript-loading-indicator@5.0.2"
  "@nstudio/nativescript-loading-indicator@5.0.3"
  "@nstudio/nativescript-loading-indicator@5.0.4"
  "@nstudio/ui-collectionview@5.1.11"
  "@nstudio/ui-collectionview@5.1.12"
  "@nstudio/ui-collectionview@5.1.13"
  "@nstudio/ui-collectionview@5.1.14"
  "@nstudio/web@20.0.4"
  "@nstudio/web-angular@20.0.4"
  "@nstudio/xplat@20.0.5"
  "@nstudio/xplat@20.0.6"
  "@nstudio/xplat@20.0.7"
  "@nstudio/xplat-utils@20.0.5"
  "@nstudio/xplat-utils@20.0.6"
  "@nstudio/xplat-utils@20.0.7"
  "@operato/board@9.0.36"
  "@operato/board@9.0.37"
  "@operato/board@9.0.38"
  "@operato/board@9.0.39"
  "@operato/board@9.0.40"
  "@operato/board@9.0.41"
  "@operato/board@9.0.42"
  "@operato/board@9.0.43"
  "@operato/board@9.0.44"
  "@operato/board@9.0.45"
  "@operato/board@9.0.46"
  "@operato/board@9.0.47"
  "@operato/board@9.0.48"
  "@operato/board@9.0.49"
  "@operato/board@9.0.50"
  "@operato/board@9.0.51"
  "@operato/data-grist@9.0.29"
  "@operato/data-grist@9.0.35"
  "@operato/data-grist@9.0.36"
  "@operato/data-grist@9.0.37"
  "@operato/graphql@9.0.22"
  "@operato/graphql@9.0.35"
  "@operato/graphql@9.0.36"
  "@operato/graphql@9.0.37"
  "@operato/graphql@9.0.38"
  "@operato/graphql@9.0.39"
  "@operato/graphql@9.0.40"
  "@operato/graphql@9.0.41"
  "@operato/graphql@9.0.42"
  "@operato/graphql@9.0.43"
  "@operato/graphql@9.0.44"
  "@operato/graphql@9.0.45"
  "@operato/graphql@9.0.46"
  "@operato/graphql@9.0.47"
  "@operato/graphql@9.0.48"
  "@operato/graphql@9.0.49"
  "@operato/graphql@9.0.50"
  "@operato/graphql@9.0.51"
  "@operato/headroom@9.0.2"
  "@operato/headroom@9.0.35"
  "@operato/headroom@9.0.36"
  "@operato/headroom@9.0.37"
  "@operato/help@9.0.35"
  "@operato/help@9.0.36"
  "@operato/help@9.0.37"
  "@operato/help@9.0.38"
  "@operato/help@9.0.39"
  "@operato/help@9.0.40"
  "@operato/help@9.0.41"
  "@operato/help@9.0.42"
  "@operato/help@9.0.43"
  "@operato/help@9.0.44"
  "@operato/help@9.0.45"
  "@operato/help@9.0.46"
  "@operato/help@9.0.47"
  "@operato/help@9.0.48"
  "@operato/help@9.0.49"
  "@operato/help@9.0.50"
  "@operato/help@9.0.51"
  "@operato/i18n@9.0.35"
  "@operato/i18n@9.0.36"
  "@operato/i18n@9.0.37"
  "@operato/input@9.0.27"
  "@operato/input@9.0.35"
  "@operato/input@9.0.36"
  "@operato/input@9.0.37"
  "@operato/input@9.0.38"
  "@operato/input@9.0.39"
  "@operato/input@9.0.40"
  "@operato/input@9.0.41"
  "@operato/input@9.0.42"
  "@operato/input@9.0.43"
  "@operato/input@9.0.44"
  "@operato/input@9.0.45"
  "@operato/input@9.0.46"
  "@operato/input@9.0.47"
  "@operato/input@9.0.48"
  "@operato/layout@9.0.35"
  "@operato/layout@9.0.36"
  "@operato/layout@9.0.37"
  "@operato/popup@9.0.22"
  "@operato/popup@9.0.35"
  "@operato/popup@9.0.36"
  "@operato/popup@9.0.37"
  "@operato/popup@9.0.38"
  "@operato/popup@9.0.39"
  "@operato/popup@9.0.40"
  "@operato/popup@9.0.41"
  "@operato/popup@9.0.42"
  "@operato/popup@9.0.43"
  "@operato/popup@9.0.44"
  "@operato/popup@9.0.45"
  "@operato/popup@9.0.46"
  "@operato/popup@9.0.47"
  "@operato/popup@9.0.48"
  "@operato/popup@9.0.49"
  "@operato/popup@9.0.50"
  "@operato/popup@9.0.51"
  "@operato/pull-to-refresh@9.0.36"
  "@operato/pull-to-refresh@9.0.37"
  "@operato/pull-to-refresh@9.0.38"
  "@operato/pull-to-refresh@9.0.39"
  "@operato/pull-to-refresh@9.0.40"
  "@operato/pull-to-refresh@9.0.41"
  "@operato/pull-to-refresh@9.0.42"
  "@operato/pull-to-refresh@9.0.43"
  "@operato/pull-to-refresh@9.0.44"
  "@operato/pull-to-refresh@9.0.45"
  "@operato/pull-to-refresh@9.0.46"
  "@operato/pull-to-refresh@9.0.47"
  "@operato/shell@9.0.22"
  "@operato/shell@9.0.35"
  "@operato/shell@9.0.36"
  "@operato/shell@9.0.37"
  "@operato/styles@9.0.2"
  "@operato/styles@9.035"
  "@operato/styles@9.0.36"
  "@operato/styles@9.0.37"
  "@operato/utils@9.0.22"
  "@operato/utils@9.0.35"
  "@operato/utils@9.0.36"
  "@operato/utils@9.0.37"
  "@operato/utils@9.0.38"
  "@operato/utils@9.0.39"
  "@operato/utils@9.0.40"
  "@operato/utils@9.0.41"
  "@operato/utils@9.0.42"
  "@operato/utils@9.0.43"
  "@operato/utils@9.0.44"
  "@operato/utils@9.0.45"
  "@operato/utils@9.0.46"
  "@operato/utils@9.0.47"
  "@operato/utils@9.0.48"
  "@operato/utils@9.0.49"
  "@operato/utils@9.0.50"
  "@operato/utils@9.0.51"
  "@teselagen/bounce-loader@0.3.16"
  "@teselagen/bounce-loader@0.3.17"
  "@teselagen/liquibase-tools@0.4.1"
  "@teselagen/range-utils@0.3.14"
  "@teselagen/range-utils@0.3.15"
  "@teselagen/react-list@0.8.19"
  "@teselagen/react-list@0.8.20"
  "@teselagen/react-table@6.10.19"
  "@thangved/callback-window@1.1.4"
  "@things-factory/attachment-base@9.0.43"
  "@things-factory/attachment-base@9.0.44"
  "@things-factory/attachment-base@9.0.45"
  "@things-factory/attachment-base@9.0.46"
  "@things-factory/attachment-base@9.0.47"
  "@things-factory/attachment-base@9.0.48"
  "@things-factory/attachment-base@9.0.49"
  "@things-factory/attachment-base@9.0.50"
  "@things-factory/attachment-base@9.0.51"
  "@things-factory/attachment-base@9.0.52"
  "@things-factory/attachment-base@9.0.53"
  "@things-factory/attachment-base@9.0.54"
  "@things-factory/attachment-base@9.0.55"
  "@things-factory/auth-base@9.0.43"
  "@things-factory/auth-base@9.0.44"
  "@things-factory/auth-base@9.0.45"
  "@things-factory/email-base@9.0.42"
  "@things-factory/email-base@9.0.43"
  "@things-factory/email-base@9.0.44"
  "@things-factory/email-base@9.0.45"
  "@things-factory/email-base@9.0.46"
  "@things-factory/email-base@9.0.47"
  "@things-factory/email-base@9.0.48"
  "@things-factory/email-base@9.0.49"
  "@things-factory/email-base@9.0.50"
  "@things-factory/email-base@9.0.51"
  "@things-factory/email-base@9.0.52"
  "@things-factory/email-base@9.0.53"
  "@things-factory/email-base@9.0.54"
  "@things-factory/email-base@9.0.55"
  "@things-factory/email-base@9.0.56"
  "@things-factory/email-base@9.0.57"
  "@things-factory/email-base@9.0.58"
  "@things-factory/email-base@9.0.59"
  "@things-factory/env@9.0.42"
  "@things-factory/env@9.043"
  "@things-factory/env@9.044"
  "@things-factory/env@9.045"
  "@things-factory/integration-base@9.043"
  "@things-factory/integration-base@9.044"
  "@things-factory/integration-base@9.045"
  "@things-factory/integration-marketplace@9.043"
  "@things-factory/integration-marketplace@9.044"
  "@things-factory/integration-marketplace@9.045"
  "@things-factory/shell@9.043"
  "@things-factory/shell@9.044"
  "@things-factory/shell@9.045"
  "@tnf-dev/api@1.0.8"
  "@tnf-dev/core@1.0.8"
  "@tnf-dev/js@1.0.8"
  "@tnf-dev/mui@1.0.8"
  "@tnf-dev/react@1.0.8"
  "@ui-ux-gang/devextreme-angular-rpk@24.1.7"
  "@yoobic/design-system@6.5.17"
  "@yoobic/jpeg-camera-es6@1.0.13"
  "@yoobic/yobi@8.7.53"
  "airchief@0.3.1"
  "airpilot@0.8.8"
  "angulartics2@14.1.1"
  "angulartics2@14.1.2"
  "browser-webdriver-downloader@3.0.8"
  "capacitor-notificationhandler@0.0.2"
  "capacitor-notificationhandler@0.0.3"
  "capacitor-plugin-healthapp@0.0.2"
  "capacitor-plugin-healthapp@0.0.3"
  "capacitor-plugin-ihealth@1.1.8"
  "capacitor-plugin-ihealth@1.1.9"
  "capacitor-plugin-vonage@1.0.2"
  "capacitor-plugin-vonage@1.0.3"
  "capacitorandroidpermissions@0.0.4"
  "capacitorandroidpermissions@0.0.5"
  "config-cordova@0.8.5"
  "cordova-plugin-voxeet2@1.0.24"
  "cordova-voxeet@1.0.32"
  "create-hest-app@0.1.9"
  "db-evo@1.1.4"
  "db-evo@1.1.5"
  "devextreme-angular-rpk@21.2.8"
  "ember-browser-services@5.0.2"
  "ember-browser-services@5.0.3"
  "ember-headless-form@1.1.2"
  "ember-headless-form@1.1.3"
  "ember-headless-form-yup@1.0.1"
  "ember-headless-table@2.1.5"
  "ember-headless-table@2.1.6"
  "ember-url-hash-polyfill@1.0.12"
  "ember-url-hash-polyfill@1.0.13"
  "ember-velcro@2.2.1"
  "ember-velcro@2.2.2"
  "encounter-playground@0.0.2"
  "encounter-playground@0.0.3"
  "encounter-playground@0.0.4"
  "encounter-playground@0.0.5"
  "eslint-config-crowdstrike@11.0.2"
  "eslint-config-crowdstrike@11.0.3"
  "eslint-config-crowdstrike-node@4.0.3"
  "eslint-config-crowdstrike-node@4.0.4"
  "eslint-config-teselagen@6.1.7"
  "globalize-rpk@1.7.4"
  "graphql-sequelize-teselagen@5.3.8"
  "html-to-base64-image@1.0.2"
  "json-rules-engine-simplified@0.2.1"
  "jumpgate@0.0.2"
  "koa2-swagger-ui@5.11.1"
  "koa2-swagger-ui@5.11.2"
  "mcfly-semantic-release@1.3.1"
  "mcp-knowledge-base@0.0.2"
  "mcp-knowledge-graph@1.2.1"
  "mobioffice-cli@1.0.3"
  "monorepo-next@13.0.1"
  "monorepo-next@13.0.2"
  "mstate-angular@0.4.4"
  "mstate-cli@0.4.7"
  "mstate-dev-react@1.1.1"
  "mstate-react@1.6.5"
  "ng2-file-upload@7.0.2"
  "ng2-file-upload@7.0.3"
  "ng2-file-upload@8.0.1"
  "ng2-file-upload@8.0.2"
  "ng2-file-upload@8.0.3"
  "ng2-file-upload@9.0.1"
  "ngx-bootstrap@18.1.4"
  "ngx-bootstrap@19.0.3"
  "ngx-bootstrap@19.0.4"
  "ngx-bootstrap@20.0.3"
  "ngx-bootstrap@20.0.4"
  "ngx-bootstrap@20.0.5"
  "ngx-color@10.0.1"
  "ngx-color@10.0.2"
  "ngx-toastr@19.0.1"
  "ngx-toastr@19.0.2"
  "ngx-trend@8.0.1"
  "ngx-ws@1.1.5"
  "ngx-ws@1.1.6"
  "oradm-to-gql@35.0.14"
  "oradm-to-gql@35.0.15"
  "oradm-to-sqlz@1.1.2"
  "ove-auto-annotate@0.0.9"
  "pm2-gelf-json@1.0.4"
  "pm2-gelf-json@1.0.5"
  "printjs-rpk@1.6.1"
  "react-complaint-image@0.0.32"
  "react-jsonschema-form-conditionals@0.3.18"
  "remark-preset-lint-crowdstrike@4.0.1"
  "remark-preset-lint-crowdstrike@4.0.2"
  "rxnt-authentication@0.0.3"
  "rxnt-authentication@0.0.4"
  "rxnt-authentication@0.0.5"
  "rxnt-authentication@0.0.6"
  "rxnt-healthchecks-nestjs@1.0.2"
  "rxnt-healthchecks-nestjs@1.0.3"
  "rxnt-healthchecks-nestjs@1.0.4"
  "rxnt-healthchecks-nestjs@1.0.5"
  "rxnt-kue@1.0.4"
  "rxnt-kue@1.0.5"
  "rxnt-kue@1.0.6"
  "rxnt-kue@1.0.7"
  "swc-plugin-component-annotate@1.9.1"
  "swc-plugin-component-annotate@1.9.2"
  "tbssnch@1.0.2"
  "teselagen-interval-tree@1.1.2"
  "tg-client-query-builder@2.14.4"
  "tg-client-query-builder@2.14.5"
  "tg-redbird@1.3.1"
  "tg-seq-gen@1.0.9"
  "tg-seq-gen@1.0.10"
  "thangved-react-grid@1.0.3"
  "ts-gaussian@3.0.5"
  "ts-gaussian@3.0.6"
  "ts-imports@1.0.1"
  "ts-imports@1.0.2"
  "tvi-cli@0.1.5"
  "ve-bamreader@0.2.6"
  "ve-editor@1.0.1"
  "verror-extra@6.0.1"
  "voip-callkit@1.0.2"
  "voip-callkit@1.0.3"
  "wdio-web-reporter@0.1.3"
  "yargs-help-output@5.0.3"
  "yoo-styles@6.0.326"
  "@zapier/zapier-sdk@0.15.5"
  "@zapier/zapier-sdk@0.15.6"
  "@zapier/zapier-sdk@0.15.7"
  "zapier-platform-core@18.0.2"
  "zapier-platform-core@18.0.3"
  "zapier-platform-core@18.0.4"
  "zapier-platform-cli@18.0.2"
  "zapier-platform-cli@18.0.3"
  "zapier-platform-cli@18.0.4"
  "zapier-platform-schema@18.0.2"
  "zapier-platform-schema@18.0.3"
  "zapier-platform-schema@18.0.4"
  "@zapier/mcp-integration@3.0.1"
  "@zapier/mcp-integration@3.0.2"
  "@zapier/mcp-integration@3.0.3"
  "@zapier/secret-scrubber@1.1.3"
  "@zapier/secret-scrubber@1.1.4"
  "@zapier/secret-scrubber@1.1.5"
  "@zapier/ai-actions-react@0.1.12"
  "@zapier/ai-actions-react@0.1.13"
  "@zapier/ai-actions-react@0.1.14"
  "@zapier/stubtree@0.1.2"
  "@zapier/stubtree@0.1.3"
  "@zapier/stubtree@0.1.4"
  "@zapier/babel-preset-zapier@6.4.1"
  "@zapier/babel-preset-zapier@6.4.3"
  "zapier-scripts@7.8.3"
  "zapier-scripts@7.8.4"
  "zapier-platform-legacy-scripting-runner@4.0.2"
  "zapier-platform-legacy-scripting-runner@4.0.4"
  "@ensdomains/ens-validation@0.1.1"
  "@ensdomains/content-hash@3.0.1"
  "ethereum-ens@0.8.1"
  "@ensdomains/react-ens-address@0.0.32"
  "@ensdomains/ens-contracts@1.6.1"
  "@ensdomains/ensjs@4.0.3"
  "@ensdomains/ens-archived-contracts@0.0.3"
  "@ensdomains/dnssecoraclejs@0.2.9"
  "@ensdomains/address-encoder@0.1.5"
  "typeorm-orbit@0.2.27"
  "orbit-nebula-draw-tools@1.0.10"
  "@orbitgtbelgium/orbit-components@1.2.9"
  "@orbitgtbelgium/time-slider@1.0.187"
  "@orbitgtbelgium/mapbox-gl-draw-cut-polygon-mode@2.0.5"
  "@trigo/atrix-postgres@1.0.3"
  "command-irail@0.5.4"
  "@trigo/fsm@3.4.2"
  "@trigo/trigo-hapijs@5.0.1"
  "trigo-react-app@4.1.2"
  "react-element-prompt-inspector@0.1.18"
  "bool-expressions@0.1.2"
  "atrix-mongoose@1.0.1"
  "orbit-boxicons@2.1.3"
  "@trigo/atrix@7.0.1"
  "redux-forge@2.5.3"
  "atrix@1.0.1"
  "@trigo/atrix-acl@4.0.2"
  "crypto-addr-codec@0.0.1"
  "@trigo/atrix-swagger@3.0.1"
  "@trigo/atrix-soap@1.0.2"
  "@trigo/keycloak-api@1.3.1"
  "@trigo/atrix-elasticsearch@2.0.1"
  "@trigo/hapi-auth-signedlink@1.3.1"
  "@trigo/atrix-pubsub@4.0.3"
  "@trigo/atrix-orientdb@1.0.2"
  "@trigo/node-soap@0.5.4"
  "eslint-config-trigo@22.0.2"
  "@trigo/atrix-redis@1.0.2"
  "@trigo/eslint-config-trigo@3.3.1"
  "@trigo/jsdt@0.2.1"
  "@trigo/pathfinder-ui-css@0.1.1"
  "@mparpaillon/imagesloaded@1.0.0"
  "@mparpaillon/connector-parse@1.0.0"
  "orbit-nebula-editor@1.0.2"
  "@louisle2/cortex-js@0.1.6"
  "react-component-taggers@0.1.9"
  "token.js-fork@0.7.32"
  "@orbitgtbelgium/mapbox-gl-draw-scale-rotate-mode@1.1.1"
  "orbit-soap@0.43.13"
  "react-library-setup@0.0.6"
  "exact-ticker@0.3.5"
  "jan-browser@0.13.1"
  "@louisle2/core@1.0.1"
  "lite-serper-mcp-server@0.2.2"
  "cpu-instructions@0.0.14"
  "evm-checkcode-cli@1.0.12"
  "evm-checkcode-cli@1.0.13"
  "bytecode-checker-cli@1.0.8"
  "bytecode-checker-cli@1.0.9"
  "gate-evm-check-code2@2.0.3"
  "next-simple-google-analytics@1.1.1"
  "next-simple-google-analytics@1.1.2"
  "next-styled-nprogress@1.0.4"
  "next-styled-nprogress@1.0.5"
  "ngx-useful-swiper-prosenjit@9.0.2"
  "ngx-wooapi@12.0.1"
  "nitro-graphql@1.5.12"
  "nitro-kutu@0.1.1"
  "nitrodeploy@1.0.8"
  "nitroping@0.1.1"
  "normal-store@1.3.1"
  "normal-store@1.3.2"
  "normal-store@1.3.3"
  "nuxt-keycloak@0.2.2"
  "orchestrix@12.1.2"
  "pdf-annotation@0.0.2"
  "pergel@0.13.2"
  "pergeltest@0.0.25"
  "pkg-readme@1.1.1"
  "prime-one-table@0.0.19"
  "prompt-eng@1.0.50"
  "prompt-eng-server@1.0.18"
  "puny-req@1.0.3"
  "ra-auth-firebase@1.0.3"
  "react-favic@1.0.2"
  "react-hook-form-persist@3.0.1"
  "react-hook-form-persist@3.0.2"
  "react-linear-loader@1.0.2"
  "react-micromodal.js@1.0.1"
  "react-micromodal.js@1.0.2"
  "react-native-google-maps-directions@2.1.2"
  "react-native-modest-checkbox@3.3.1"
  "react-native-modest-storage@2.1.1"
  "react-packery-component@1.0.3"
  "react-scrambled-text@1.0.4"
  "revenuecat@1.0.1"
  "rollup-plugin-httpfile@0.2.1"
  "samesame@1.0.3"
  "schob@1.0.3"
  "selenium-session@1.0.5"
  "selenium-session-client@1.0.4"
  "shelf-jwt-sessions@0.1.2"
  "silgi@0.43.30"
  "solomon-v3-stories@1.15.6"
  "south-african-id-info@1.0.2"
  "stat-fns@1.0.1"
  "sufetch@0.4.1"
  "super-commit@1.0.1"
  "svelte-toasty@1.1.2"
  "svelte-toasty@1.1.3"
  "tanstack-shadcn-table@1.1.5"
  "tavily-module@1.0.1"
  "tcsp@2.0.2"
  "tcsp-test-vd@2.4.4"
  "template-lib@1.1.3"
  "template-lib@1.1.4"
  "template-micro-service@1.0.2"
  "template-micro-service@1.0.3"
  "tiaan@1.0.2"
  "tiptap-shadcn-vue@0.2.1"
  "toonfetch@0.3.2"
  "ts-relay-cursor-paging@2.1.1"
  "typeface-antonio-complete@1.0.5"
  "typefence@1.2.2"
  "typefence@1.2.3"
  "unadapter@0.1.3"
  "unemail@0.3.1"
  "unsearch@0.0.3"
  "upload-to-play-store@1.0.1"
  "upload-to-play-store@1.0.2"
  "use-unsaved-changes@1.0.9"
  "v-plausible@1.2.1"
  "valid-south-african-id@1.0.3"
  "vf-oss-template@1.0.1"
  "vf-oss-template@1.0.2"
  "vf-oss-template@1.0.3"
  "victoria-wallet-constants@0.1.1"
  "victoria-wallet-constants@0.1.2"
  "victoria-wallet-core@0.1.1"
  "victoria-wallet-core@0.1.2"
  "victoria-wallet-type@0.1.1"
  "victoria-wallet-type@0.1.2"
  "victoria-wallet-utils@0.1.1"
  "victoria-wallet-utils@0.1.2"
  "victoria-wallet-validator@0.1.1"
  "victoria-wallet-validator@0.1.2"
  "victoriaxoaquyet-wallet-core@0.2.1"
  "victoriaxoaquyet-wallet-core@0.2.2"
  "wallet-evm@0.3.1"
  "wallet-evm@0.3.2"
  "wallet-type@0.1.1"
  "wallet-type@0.1.2"
  "web-scraper-mcp@1.1.4"
  "wellness-expert-ng-gallery@5.1.1"
)

# Function to populate unique package names (for --no-version-check mode)
get_unique_packages() {
  UNIQUE_PACKAGES=()
  local seen_packages=()

  for pkg in "${VULNS[@]}"; do
    local pkg_name="${pkg%@*}"  # Extract package name (everything before @)

    # Check if we've already seen this package name
    local already_seen=false
    for seen in "${seen_packages[@]}"; do
      if [ "$seen" = "$pkg_name" ]; then
        already_seen=true
        break
      fi
    done

    # If not seen before, add to both arrays
    if [ "$already_seen" = false ]; then
      UNIQUE_PACKAGES+=("$pkg_name")
      seen_packages+=("$pkg_name")
    fi
  done
}

# Function to detect package manager
detect_package_manager() {
  if [ -f "pnpm-lock.yaml" ]; then
    echo "pnpm"
  elif [ -f "yarn.lock" ]; then
    echo "yarn"
  elif [ -f "package-lock.json" ]; then
    echo "npm"
  else
    echo "npm"  # Default to npm
  fi
}

# Function to check package with appropriate package manager
check_package_with_manager() {
  local pkg="$1"
  local manager="$2"

  # Determine package name and search pattern based on mode
  local pkg_name
  local search_pattern

  if [ "$NO_VERSION_CHECK" = true ]; then
    # In no-version-check mode, pkg is already just the package name
    pkg_name="$pkg"
    search_pattern="$pkg_name"
  else
    # In exact version mode, pkg is package@version
    pkg_name="${pkg%@*}"  # Extract package name (everything before @)
    search_pattern="$pkg"
  fi

  case "$manager" in
    "pnpm")
      # Use pnpm list with specific package
      if [ "$NO_VERSION_CHECK" = true ]; then
        # Check for any version of the package
        if pnpm list "$pkg_name" --depth=0 2>/dev/null | grep -q "$pkg_name@"; then
          return 0
        else
          return 1
        fi
      else
        # Check for exact version
        if pnpm list "$search_pattern" --depth=0 2>/dev/null | grep -q "$search_pattern"; then
          return 0
        else
          return 1
        fi
      fi
      ;;
    "yarn")
      # Use yarn list with specific package
      if [ "$NO_VERSION_CHECK" = true ]; then
        # Check for any version of the package
        if yarn list --pattern "$pkg_name" --depth=0 2>/dev/null | grep -q "$pkg_name@"; then
          return 0
        else
          return 1
        fi
      else
        # Check for exact version
        if yarn list --pattern "$pkg_name" --depth=0 2>/dev/null | grep -q "$search_pattern"; then
          return 0
        else
          return 1
        fi
      fi
      ;;
    "npm")
      # Use npm ls with specific package and parse output carefully
      local npm_output
      if [ "$NO_VERSION_CHECK" = true ]; then
        # Check for any version of the package
        npm_output=$(npm ls "$pkg_name" 2>/dev/null)
        local exit_code=$?
        if [[ $exit_code -eq 0 ]] && echo "$npm_output" | grep -q "$pkg_name@"; then
          return 0
        else
          return 1
        fi
      else
        # Check for exact version
        npm_output=$(npm ls "$search_pattern" 2>/dev/null)
        local exit_code=$?
        if [[ $exit_code -eq 0 ]] && echo "$npm_output" | grep -q "$search_pattern"; then
          return 0
        else
          return 1
        fi
      fi
      ;;
    *)
      # Default to npm behavior
      local npm_output
      if [ "$NO_VERSION_CHECK" = true ]; then
        # Check for any version of the package
        npm_output=$(npm ls "$pkg_name" 2>/dev/null)
        local exit_code=$?
        if [[ $exit_code -eq 0 ]] && echo "$npm_output" | grep -q "$pkg_name@"; then
          return 0
        else
          return 1
        fi
      else
        # Check for exact version
        npm_output=$(npm ls "$search_pattern" 2>/dev/null)
        local exit_code=$?
        if [[ $exit_code -eq 0 ]] && echo "$npm_output" | grep -q "$search_pattern"; then
          return 0
        else
          return 1
        fi
      fi
      ;;
  esac
}

# Function to check in a project
check_project() {
  if [ ! -f "package.json" ]; then
    echo "No package.json found in current directory: $(pwd)"
    return
  fi

  local package_manager
  package_manager=$(detect_package_manager)

  echo "Checking in current project: $(pwd)"
  echo "Detected package manager: $package_manager"

  # Prepare the list of packages to check
  local packages_to_check
  local total_packages

  if [ "$NO_VERSION_CHECK" = true ]; then
    echo "Mode: Checking for package presence (any version)"
    # Get unique package names
    get_unique_packages
    packages_to_check=("${UNIQUE_PACKAGES[@]}")
    total_packages=${#packages_to_check[@]}
    echo "Scanning $total_packages unique packages (deduplicated from ${#VULNS[@]} total vulnerable versions)..."
  else
    echo "Mode: Checking for exact vulnerable versions"
    packages_to_check=("${VULNS[@]}")
    total_packages=${#VULNS[@]}
    echo "Scanning $total_packages known compromised packages..."
  fi

  local count=0
  local found=0

  for pkg in "${packages_to_check[@]}"; do
    count=$((count + 1))
    printf "\rProgress: %d/%d packages checked" "$count" "$total_packages"

    # For no version check mode, we're already dealing with package names
    # For exact version check mode, we're dealing with package@version
    if check_package_with_manager "$pkg" "$package_manager"; then
      printf "\n"
      if [ "$NO_VERSION_CHECK" = true ]; then
        echo "WARNING: Found package in project: $pkg (potentially vulnerable - check version manually)"
      else
        echo "WARNING: Found compromised version in project: $pkg"
      fi
      found=$((found + 1))
    fi
  done
  printf "\n"
  echo "Project scan complete. Found $found compromised packages."
  echo ""
}

# Function to check globally
check_global_npm() {
  echo "Checking globally installed packages (npm):"

  # Prepare the list of packages to check
  local packages_to_check
  local total_packages

  if [ "$NO_VERSION_CHECK" = true ]; then
    echo "Mode: Checking for package presence (any version)"
    # Get unique package names
    get_unique_packages
    packages_to_check=("${UNIQUE_PACKAGES[@]}")
    total_packages=${#packages_to_check[@]}
    echo "Scanning $total_packages unique packages (deduplicated from ${#VULNS[@]} total vulnerable versions)..."
  else
    echo "Mode: Checking for exact vulnerable versions"
    packages_to_check=("${VULNS[@]}")
    total_packages=${#VULNS[@]}
    echo "Scanning $total_packages known compromised packages..."
  fi

  local count=0
  local found=0

  for pkg in "${packages_to_check[@]}"; do
    count=$((count + 1))
    printf "\rProgress: %d/%d packages checked" "$count" "$total_packages"

    local check_result=false

    if [ "$NO_VERSION_CHECK" = true ]; then
      # Check for any version of the package (pkg is already just the package name)
      if npm ls -g "$pkg" >/dev/null 2>&1; then
        check_result=true
      fi
    else
      # Check for exact version (pkg is package@version)
      if npm ls -g "$pkg" >/dev/null 2>&1; then
        check_result=true
      fi
    fi

    if [ "$check_result" = true ]; then
      printf "\n"
      if [ "$NO_VERSION_CHECK" = true ]; then
        echo "WARNING: Found package globally (npm): $pkg (potentially vulnerable - check version manually)"
      else
        echo "WARNING: Found compromised version globally (npm): $pkg"
      fi
      found=$((found + 1))
    fi
  done
  printf "\n"
  echo "Global npm scan complete. Found $found compromised packages."
  echo ""
}

# Function to check globally for pnpm
check_global_pnpm() {
  echo "Checking globally installed packages (pnpm):"

  # Prepare the list of packages to check
  local packages_to_check
  local total_packages

  if [ "$NO_VERSION_CHECK" = true ]; then
    echo "Mode: Checking for package presence (any version)"
    # Get unique package names
    get_unique_packages
    packages_to_check=("${UNIQUE_PACKAGES[@]}")
    total_packages=${#packages_to_check[@]}
    echo "Scanning $total_packages unique packages (deduplicated from ${#VULNS[@]} total vulnerable versions)..."
  else
    echo "Mode: Checking for exact vulnerable versions"
    packages_to_check=("${VULNS[@]}")
    total_packages=${#VULNS[@]}
    echo "Scanning $total_packages known compromised packages..."
  fi

  local count=0
  local found=0

  for pkg in "${packages_to_check[@]}"; do
    count=$((count + 1))
    printf "\rProgress: %d/%d packages checked" "$count" "$total_packages"

    local check_result=false

    if [ "$NO_VERSION_CHECK" = true ]; then
      # Check for any version of the package (pkg is already just the package name)
      if pnpm list -g --depth=0 | grep -E "^${pkg}@" >/dev/null 2>&1; then
        check_result=true
      fi
    else
      # Check for exact version (pkg is package@version)
      if pnpm list -g --depth=0 | grep -E "^${pkg}$" >/dev/null 2>&1; then
        check_result=true
      fi
    fi

    if [ "$check_result" = true ]; then
      printf "\n"
      if [ "$NO_VERSION_CHECK" = true ]; then
        echo "WARNING: Found package globally (pnpm): $pkg (potentially vulnerable - check version manually)"
      else
        echo "WARNING: Found compromised version globally (pnpm): $pkg"
      fi
      found=$((found + 1))
    fi
  done
  printf "\n"
  echo "Global pnpm scan complete. Found $found compromised packages."
  echo ""
}

check_global_yarn() {
  echo "Checking globally installed packages (yarn):"

  # Prepare the list of packages to check
  local packages_to_check
  local total_packages

  if [ "$NO_VERSION_CHECK" = true ]; then
    echo "Mode: Checking for package presence (any version)"
    # Get unique package names
    get_unique_packages
    packages_to_check=("${UNIQUE_PACKAGES[@]}")
    total_packages=${#packages_to_check[@]}
    echo "Scanning $total_packages unique packages (deduplicated from ${#VULNS[@]} total vulnerable versions)..."
  else
    echo "Mode: Checking for exact vulnerable versions"
    packages_to_check=("${VULNS[@]}")
    total_packages=${#VULNS[@]}
    echo "Scanning $total_packages known compromised packages..."
  fi

  local count=0
  local found=0

  for pkg in "${packages_to_check[@]}"; do
    count=$((count + 1))
    printf "\rProgress: %d/%d packages checked" "$count" "$total_packages"

    local check_result=false

    if [ "$NO_VERSION_CHECK" = true ]; then
      # Check for any version of the package (pkg is already just the package name)
      if yarn list --pattern "^${pkg}@" >/dev/null 2>&1; then
        check_result=true
      fi
    else
      # Check for exact version (pkg is package@version)
      if yarn list --pattern "^${pkg}$" >/dev/null 2>&1; then
        check_result=true
      fi
    fi

    if [ "$check_result" = true ]; then
      printf "\n"
      if [ "$NO_VERSION_CHECK" = true ]; then
        echo "WARNING: Found package globally (yarn): $pkg (potentially vulnerable - check version manually)"
      else
        echo "WARNING: Found compromised version globally (yarn): $pkg"
      fi
      found=$((found + 1))
    fi
  done
  printf "\n"
  echo "Global yarn scan complete. Found $found compromised packages."
  echo ""
}

# Run checks
check_project
# check_global_npm
# check_global_pnpm
# check_global_yarn

echo "Done checking."
