#!/bin/bash

# Fixes driver and performance issues on HP ENVY 15 (Intel HD 4600 + NVIDIA 840M, BCM4352 WiFi).
# Tested on Fedora 43, KDE Plasma 6, Wayland, kernel 6.x.
#
# Run once after a fresh Fedora install. Safe to re-run (idempotent).
#
# PHYSICAL STEP (can't automate): clean heatsink + repaste CPU.
# CPU idles at 75-89°C on this machine — above the 84°C high threshold.
# Thermal throttling is the #1 cause of sluggishness in VSCode/Zed/browser.

set -e

log() { echo ""; echo ">>> $1"; }

# ── 1. NVIDIA DRM modeset (required for KDE Wayland + NVIDIA) ────────────────
# Without modeset=1, KWin falls back to suboptimal rendering paths on Wayland,
# causing scroll jank and compositor lag.
log "[1/3] Enabling NVIDIA DRM modeset..."

NVIDIA_CONF=/etc/modprobe.d/nvidia.conf

if grep -q "modeset=1" "$NVIDIA_CONF" 2>/dev/null; then
    echo "Already set — skipping."
else
    sudo tee "$NVIDIA_CONF" > /dev/null <<EOF
options nvidia-drm modeset=1 fbdev=1
EOF
    echo "Written $NVIDIA_CONF"

    echo "Regenerating initramfs (dracut)..."
    sudo dracut --force
    echo "Done. Reboot required."
fi

# ── 2. Broadcom BCM4352 WiFi driver ──────────────────────────────────────────
# Default driver (bcma-pci-bridge) is a stub — no wlan interface appears.
# akmod-wl from RPM Fusion builds the proprietary Broadcom wl kernel module.
log "[2/3] Installing Broadcom BCM4352 WiFi driver (akmod-wl)..."

if lsmod | grep -q "^wl "; then
    echo "wl module already loaded — skipping."
else
    # Ensure RPM Fusion free + nonfree repos are present
    if ! rpm -q rpmfusion-nonfree-release &>/dev/null; then
        echo "Adding RPM Fusion nonfree repo..."
        sudo dnf install -y \
            "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
            "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
    fi

    sudo dnf install -y akmod-wl

    echo "Building wl kernel module (akmods)..."
    sudo akmods --force

    echo "Loading wl module..."
    sudo modprobe wl || echo "Module load failed — reboot may be required."
fi

# ── 3. NVIDIA PRIME (Optimus offloading) ─────────────────────────────────────
# Fedora's xorg-x11-drv-nvidia does not ship a prime-run script.
# Create one manually — it just sets the three env vars NVIDIA needs for
# PRIME render offload on a hybrid Intel+NVIDIA system.
log "[3/3] Creating prime-run wrapper..."

if command -v prime-run &>/dev/null; then
    echo "prime-run already available — skipping."
else
    sudo tee /usr/local/bin/prime-run > /dev/null <<'EOF'
#!/bin/bash
# GLX (XWayland/X11) offload
__NV_PRIME_RENDER_OFFLOAD=1 \
__GLX_VENDOR_LIBRARY_NAME=nvidia \
__VK_LAYER_NV_optimus=NVIDIA_only \
__EGL_VENDOR_LIBRARY_FILENAMES=/usr/share/glvnd/egl_vendor.d/10_nvidia.json \
exec "$@"
EOF
    sudo chmod +x /usr/local/bin/prime-run
    echo "Created /usr/local/bin/prime-run. Use: prime-run <app>"
fi

# ── Done ─────────────────────────────────────────────────────────────────────
echo ""
echo ">>> Done."
echo ""
echo "Next steps:"
echo "  1. REBOOT — modeset + WiFi module require it."
echo "  2. PHYSICAL: clean heatsink + replace thermal paste."
echo "     CPU temps 75-89°C (high threshold: 84°C) = thermal throttling."
echo "     No software fix for this."
echo "  3. Optional: use 'prime-run <app>' to offload to NVIDIA 840M."
