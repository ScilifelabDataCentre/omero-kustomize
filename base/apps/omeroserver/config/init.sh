#!/usr/bin/env sh
set -eu

echo "Setting up OMERO data directory permissions..."
chown -R 1000:1000 /OMERO || true
chmod -R 755 /OMERO || true

mkdir -p /OMERO/certs /OMERO/var/registry /OMERO/tmp /OMERO/etc
chown -R 1000:1000 /OMERO/certs /OMERO/var /OMERO/tmp /OMERO/etc || true

if [ -f /config/ice.config ]; then
  tr -d '\r' < /config/ice.config > /OMERO/etc/ice.config.tmp
  mv /OMERO/etc/ice.config.tmp /OMERO/etc/ice.config
  chown 1000:1000 /OMERO/etc/ice.config
  chmod 0644 /OMERO/etc/ice.config
  echo "Copied ice.config to /OMERO/etc/ice.config"

  echo "Validating ice.config:"
  grep -E '^(IceGrid\.Registry\.(Client|Server|Internal)\.Endpoints|Ice\.Default\.Locator|IceGrid\.Registry\.Data)=' /OMERO/etc/ice.config || {
    echo "ERROR: ice.config missing required properties"; exit 1;
  }
else
  echo "WARN: /config/ice.config not found; server will use its default Ice settings"
fi

echo "Cleaning up OMERO lock files..."
find /OMERO -name "*.lock" -type f -delete || true
echo "OMERO directory setup completed"
