#!/bin/bash
# First-run setup for voxtype: pull the default Whisper model (base.en, ~142 MB)
# and let it verify the install (audio source, typing backend, permissions).
#
# Idempotent: the download is skipped when the model is already on disk, so
# re-applying on an existing machine is a no-op. An offline install fails
# softly — the model can be fetched later with `voxtype setup --download`.

set -uo pipefail

command -v voxtype >/dev/null 2>&1 || exit 0

models="${XDG_DATA_HOME:-$HOME/.local/share}/voxtype/models"
if ! compgen -G "$models/*base.en*" >/dev/null; then
  if ! voxtype setup --download; then
    echo "install-voxtype: model download failed; run 'voxtype setup --download' manually" >&2
    exit 0
  fi
fi

# the service may already have been started by setup-user-services before the
# model existed, in which case it failed and hit systemd's start limit
systemctl --user reset-failed voxtype.service 2>/dev/null
systemctl --user restart voxtype.service 2>/dev/null

exit 0
