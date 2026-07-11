# CLI integration modules for caelestia-cli multi-distro support.
#
# These modules are intended to be merged into the caelestia-dots/cli repository.
# They add Fedora support through:
#
#   src/caelestia/distro.py       — detects Arch vs Fedora
#   src/caelestia/pkg/dnf.py      — DNF package manager backend
#   src/caelestia/pkg/pacman.py   — (enhanced) pacman + AUR helper backend
#
# Integration points in the existing CLI codebase:
#
# 1. Replace hardcoded pacman/AUR calls in src/caelestia/install.py
#    with the factory in pkg/__init__.py:
#
#        from caelestia.pkg import get_package_backend
#        backend = get_package_backend()
#        backend.install(packages)
#
# 2. Add COPR handling to the manifest parser (src/caelestia/manifest.py)
#    so the [copr] section in manifest-fedora.toml gets processed.
#
# 3. Extend the install subcommand to:
#    - Load manifest.toml vs manifest-fedora.toml based on detected distro
#    - Call backend.enable_copr() for each COPR before installing
#    - Call backend.enable_rpmfusion() on Fedora
#
# 4. Make post-install hooks distro-aware (e.g. fc-cache on Fedora).
