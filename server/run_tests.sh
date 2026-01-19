#!/usr/bin/env bash
# Simple test runner wrapper that uses the test settings to run tests
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

export DJANGO_SETTINGS_MODULE=apo_basi.test_settings

python manage.py test "$@"
