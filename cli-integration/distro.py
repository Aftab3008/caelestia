"""
Distro detection for caelestia-cli.

Provides unified distro identification across Linux distributions,
enabling the CLI to adapt package install, COPR setup, and post-install
hooks to the host OS.

Usage:
    from caelestia.distro import detect, Distro

    distro = detect()
    if distro == Distro.FEDORA:
        ...
"""

from __future__ import annotations

import enum
import functools
import os
from typing import Optional


class Distro(enum.Enum):
    ARCH = "arch"
    FEDORA = "fedora"
    UNKNOWN = "unknown"


_ID_MAP: dict[str, Distro] = {
    "arch": Distro.ARCH,
    "fedora": Distro.FEDORA,
    "rhel": Distro.FEDORA,  # treat EL clones as Fedora-compatible
    "centos": Distro.FEDORA,
    "rocky": Distro.FEDORA,
    "almalinux": Distro.FEDORA,
    "nobara": Distro.FEDORA,  # Fedora derivative
    "bluefin": Distro.FEDORA,  # Fedora atomic
    "aurora": Distro.FEDORA,   # Fedora atomic
    "bazzite": Distro.FEDORA,  # Fedora atomic
}

# Distros that use the AUR / pacman
_AUR_IDS: set[str] = {
    "arch", "manjaro", "endeavouros", "garuda", "artix",
    "cachyos", "arcolinux", "archcraft", "archbang",
    "blendos", "crystal", "exherbo", "parabola", "rebornos",
}


@functools.lru_cache(maxsize=1)
def detect() -> Distro:
    """Detect the running distribution.

    Reads /etc/os-release and maps the ID (and optionally ID_LIKE)
    to a known distro enum.

    Returns:
        Distro enum value.
    """

    os_release = _read_os_release()

    # Direct ID match
    distro_id = os_release.get("ID", "").lower()
    if distro_id in _ID_MAP:
        return _ID_MAP[distro_id]

    # AUR-based detection
    if distro_id in _AUR_IDS:
        return Distro.ARCH

    # Check ID_LIKE for Arch ancestry (e.g. "arch" in "arch archbang")
    id_like = os_release.get("ID_LIKE", "").lower()
    like_tokens = [t.strip() for t in id_like.split()]

    if "arch" in like_tokens:
        return Distro.ARCH
    if any(t in ("fedora", "rhel", "centos") for t in like_tokens):
        return Distro.FEDORA

    # Fallback: check for presence of key package managers
    if _command_exists("pacman"):
        return Distro.ARCH
    if _command_exists("dnf"):
        return Distro.FEDORA

    return Distro.UNKNOWN


def is_fedora() -> bool:
    """Shorthand: return True if running on Fedora or a Fedora derivative."""
    return detect() == Distro.FEDORA


def is_arch() -> bool:
    """Shorthand: return True if running on Arch or an Arch derivative."""
    return detect() == Distro.ARCH


def get_package_manager() -> str:
    """Return the system package manager command name."""
    distro = detect()
    if distro == Distro.FEDORA:
        return "dnf"
    if distro == Distro.ARCH:
        return "pacman"
    return ""


def get_fedora_version() -> int:
    """Return the Fedora major version number, or 0 if not on Fedora."""
    os_release = _read_os_release()
    try:
        return int(os_release.get("VERSION_ID", "0"))
    except ValueError:
        return 0


# ── Internal helpers ──────────────────────────────────────────────────────


def _read_os_release() -> dict[str, str]:
    """Parse /etc/os-release into a dictionary."""
    path = "/etc/os-release"
    result: dict[str, str] = {}
    if not os.path.isfile(path):
        return result
    with open(path, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            if "=" not in line:
                continue
            key, _, value = line.partition("=")
            # Strip optional quoting
            value = value.strip().strip('"').strip("'")
            result[key] = value
    return result


def _command_exists(cmd: str) -> bool:
    """Check whether a command is on PATH."""
    import shutil
    return shutil.which(cmd) is not None
