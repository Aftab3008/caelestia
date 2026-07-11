"""Pacman (ALPM) package manager backend for caelestia-cli.

Handles package installation, removal, and AUR helper integration
on Arch Linux and Arch-compatible distributions.
"""

from __future__ import annotations

import shutil
import subprocess
import shlex
from typing import List, Optional

from caelestia.distro import Distro, detect, is_arch


class PacmanBackend:
    """Interface to pacman (and optionally an AUR helper) for package operations."""

    def __init__(
        self,
        *,
        dry_run: bool = False,
        aur_helper: Optional[str] = None,
    ):
        if not is_arch():
            raise RuntimeError(
                "PacmanBackend can only be used on Arch-based systems."
            )
        self._dry_run = dry_run
        self._aur_helper = aur_helper or self._detect_aur_helper()

    # ── Public API ──────────────────────────────────────────────────────

    def install(self, packages: List[str]) -> None:
        if not packages:
            return

        # Separate official repo packages from AUR packages
        official, aur = self._classify_packages(packages)

        if official:
            self._pacman_install(official)
        if aur:
            self._aur_install(aur)

    def install_official(self, packages: List[str]) -> None:
        """Install packages from official repos only."""
        if not packages:
            return
        self._pacman_install(packages)

    def install_aur(self, packages: List[str]) -> None:
        """Install packages from AUR."""
        if not packages:
            return
        self._aur_install(packages)

    def remove(self, packages: List[str]) -> None:
        if not packages:
            return
        cmd = ["sudo", "pacman", "-Rns"]
        if self._dry_run:
            cmd.append("--print")
        cmd.extend(packages)
        _run(cmd, f"Failed to remove: {', '.join(packages)}")

    def is_installed(self, package: str) -> bool:
        result = subprocess.run(
            ["pacman", "-Q", package],
            capture_output=True, text=True,
        )
        return result.returncode == 0

    def update(self) -> None:
        if self._aur_helper:
            cmd = [self._aur_helper, "-Syu"]
            if self._dry_run:
                cmd.append("--print")
            _run(cmd, "System update failed")
        else:
            cmd = ["sudo", "pacman", "-Syu"]
            if self._dry_run:
                cmd.append("--print")
            _run(cmd, "System update failed")

    @property
    def aur_helper(self) -> Optional[str]:
        return self._aur_helper

    # ── Internal ─────────────────────────────────────────────────────────

    def _classify_packages(self, packages: List[str]) -> tuple[List[str], List[str]]:
        """Classify packages as official vs AUR.

        AUR packages typically end with '-bin', '-git', '-appimage',
        or don't exist in the official repos.
        """
        official = []
        aur = []
        for pkg in packages:
            if any(pkg.endswith(suffix) for suffix in ("-bin", "-git", "-appimage")):
                aur.append(pkg)
            else:
                official.append(pkg)
        return official, aur

    def _pacman_install(self, packages: List[str]) -> None:
        cmd = ["sudo", "pacman", "-S", "--needed"]
        if self._dry_run:
            cmd.append("--print")
        cmd.extend(packages)
        _run(cmd, f"pacman install failed: {', '.join(packages)}")

    def _aur_install(self, packages: List[str]) -> None:
        if not self._aur_helper:
            raise RuntimeError(
                "AUR packages requested but no AUR helper found. "
                f"Install yay or paru first. Packages: {', '.join(packages)}"
            )
        cmd = [self._aur_helper, "-S", "--needed"]
        if self._dry_run:
            cmd.append("--print")
        cmd.extend(packages)
        _run(cmd, f"AUR install failed: {', '.join(packages)}")

    @staticmethod
    def _detect_aur_helper() -> Optional[str]:
        for helper in ("paru", "yay", "trizen", "pamac"):
            if shutil.which(helper):
                return helper
        return None


def get_package_backend(aur_helper: Optional[str] = None):
    """Factory: return the correct backend for the current distro."""
    distro = detect()
    if distro == Distro.ARCH:
        return PacmanBackend(aur_helper=aur_helper)
    if distro == Distro.FEDORA:
        from caelestia.pkg.dnf import DnfBackend
        return DnfBackend()
    raise RuntimeError(f"Unsupported distribution: {distro}")


def _run(cmd: List[str], error_msg: str) -> None:
    print(f"  → {' '.join(shlex.quote(p) for p in cmd)}")
    result = subprocess.run(cmd)
    if result.returncode != 0:
        raise RuntimeError(error_msg)
