"""
DNF package manager backend for caelestia-cli.

Handles package installation, removal, and COPR repository management
on Fedora and Fedora-compatible distributions.

Usage:
    from caelestia.pkg.dnf import DnfBackend

    backend = DnfBackend()
    backend.install(["hyprland", "fish"])
    backend.enable_copr("solopasha/hyprland")
"""

from __future__ import annotations

import subprocess
import shlex
from typing import List

from caelestia.distro import Distro, detect, get_fedora_version


class DnfBackend:
    """Interface to dnf for package operations."""

    def __init__(self, *, dry_run: bool = False, assume_yes: bool = True):
        self._dry_run = dry_run
        self._assume_yes = assume_yes
        self._coprs_enabled: set[str] = set()

    # ── Public API ──────────────────────────────────────────────────────

    def install(self, packages: List[str]) -> None:
        """Install one or more packages."""
        if not packages:
            return
        cmd = ["sudo", "dnf", "install"]
        if self._assume_yes:
            cmd.append("-y")
        if self._dry_run:
            cmd.append("--setopt=tsflags=test")
        cmd.extend(packages)
        _run(cmd, f"Failed to install: {', '.join(packages)}")

    def remove(self, packages: List[str]) -> None:
        """Remove one or more packages."""
        if not packages:
            return
        cmd = ["sudo", "dnf", "remove"]
        if self._assume_yes:
            cmd.append("-y")
        cmd.extend(packages)
        _run(cmd, f"Failed to remove: {', '.join(packages)}")

    def is_installed(self, package: str) -> bool:
        """Check whether a package is installed."""
        result = subprocess.run(
            ["rpm", "-q", package],
            capture_output=True, text=True,
        )
        return result.returncode == 0

    def update(self) -> None:
        """Upgrade all system packages."""
        cmd = ["sudo", "dnf", "upgrade", "--refresh"]
        if self._assume_yes:
            cmd.append("-y")
        _run(cmd, "System update failed")

    # ── COPR management ─────────────────────────────────────────────────

    def enable_copr(self, copr: str) -> None:
        """Enable a COPR repository.

        Args:
            copr: Repository name in owner/project format (e.g. "solopasha/hyprland").
        """
        if copr in self._coprs_enabled:
            return

        cmd = ["sudo", "dnf", "copr", "enable"]
        if self._assume_yes:
            cmd.append("-y")
        cmd.append(copr)
        _run(cmd, f"Failed to enable COPR: {copr}")
        self._coprs_enabled.add(copr)

    def enable_multiple_coprs(self, coprs: List[str]) -> None:
        """Enable multiple COPR repos at once."""
        for copr in coprs:
            self.enable_copr(copr)

    # ── RPM Fusion ──────────────────────────────────────────────────────

    def enable_rpmfusion_free(self) -> None:
        """Enable the RPM Fusion free repository."""
        if self.is_installed("rpmfusion-free-release"):
            return
        version = get_fedora_version()
        url = (
            "https://mirrors.rpmfusion.org/free/fedora/"
            f"rpmfusion-free-release-{version}.noarch.rpm"
        )
        cmd = ["sudo", "dnf", "install", "-y", url]
        _run(cmd, "Failed to enable RPM Fusion (free)")

    def enable_rpmfusion_nonfree(self) -> None:
        """Enable the RPM Fusion nonfree repository."""
        if self.is_installed("rpmfusion-nonfree-release"):
            return
        version = get_fedora_version()
        url = (
            "https://mirrors.rpmfusion.org/nonfree/fedora/"
            f"rpmfusion-nonfree-release-{version}.noarch.rpm"
        )
        cmd = ["sudo", "dnf", "install", "-y", url]
        _run(cmd, "Failed to enable RPM Fusion (nonfree)")

    def enable_rpmfusion(self) -> None:
        """Enable both free and nonfree RPM Fusion repos."""
        self.enable_rpmfusion_free()
        self.enable_rpmfusion_nonfree()


# ── helpers ────────────────────────────────────────────────────────────────


def _run(cmd: List[str], error_msg: str) -> None:
    """Run a command, raise RuntimeError on failure.

    Output is streamed to the terminal so the user can see dnf progress.
    """
    print(f"  → {' '.join(shlex.quote(p) for p in cmd)}")
    result = subprocess.run(cmd)
    if result.returncode != 0:
        raise RuntimeError(error_msg)
