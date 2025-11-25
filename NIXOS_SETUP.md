# NixOS Setup Guide

Quick start guide for setting up NixOS on arrakis (gaming desktop) and urth (home server).

## Prerequisites

1. USB drive with NixOS installer ISO
2. Boot the target machine from USB
3. Connect to internet (ethernet or wifi)

## Installation Steps

### 1. Partition the Disk

For UEFI systems with a single disk:

```bash
# Check available disks
lsblk

# Partition (replace /dev/sdX with your disk)
sudo parted /dev/sdX -- mklabel gpt
sudo parted /dev/sdX -- mkpart ESP fat32 1MiB 512MiB
sudo parted /dev/sdX -- set 1 esp on
sudo parted /dev/sdX -- mkpart primary 512MiB 100%

# Format partitions
sudo mkfs.fat -F 32 -n boot /dev/sdX1
sudo mkfs.ext4 -L nixos /dev/sdX2

# Mount
sudo mount /dev/disk/by-label/nixos /mnt
sudo mkdir -p /mnt/boot
sudo mount /dev/disk/by-label/boot /mnt/boot
```

### 2. Generate Initial Configuration

```bash
sudo nixos-generate-config --root /mnt
```

### 3. Clone This Repository

```bash
# Install git
nix-shell -p git

# Clone the repo
cd /mnt/home
sudo git clone https://github.com/roshbhatia/sysinit.git
cd sysinit
```

### 4. Update Hardware Configuration

```bash
# Generate hardware config for this machine
sudo nixos-generate-config --show-hardware-config > /mnt/home/sysinit/hosts/<hostname>/hardware-configuration.nix

# Where <hostname> is:
# - arrakis (for gaming desktop)
# - urth (for home server)
```

**Important**: Review the generated `hardware-configuration.nix` and update:

#### For Gaming Desktop (arrakis)
- Uncomment GPU drivers based on your hardware:
  - NVIDIA: Uncomment NVIDIA section
  - AMD: Uncomment AMD section
  - Intel: Uncomment Intel section
- Update CPU microcode (`kvm-intel` or `kvm-amd`)

#### For Home Server (urth)
- Verify disk mounts
- Disable hardware OpenGL if no GPU

### 5. Install NixOS

```bash
# For arrakis (gaming desktop)
sudo nixos-install --flake /mnt/home/sysinit#arrakis

# For urth (home server)
sudo nixos-install --flake /mnt/home/sysinit#urth
```

During installation, you'll be prompted to set the root password.

### 6. Reboot

```bash
sudo reboot
```

## Post-Installation Setup

### 1. Set User Password

```bash
# Login as root first (if needed)
sudo passwd rshnbhatia
```

### 2. Clone Repository (if not already in /home)

```bash
cd ~
git clone https://github.com/roshbhatia/sysinit.git
cd sysinit
```

### 3. Apply Configuration

```bash
# For arrakis
sudo nixos-rebuild switch --flake .#arrakis

# For urth
sudo nixos-rebuild switch --flake .#urth
```

### 4. Setup Tailscale

```bash
# Start Tailscale
sudo systemctl start tailscale

# Connect to your Tailscale network
sudo tailscale up

# Verify connection
tailscale status
```

### 5. Setup SSH Keys

```bash
# Generate SSH key
ssh-keygen -t ed25519 -C "rshnbhatia@<hostname>"

# Add to GitHub
cat ~/.ssh/id_ed25519.pub
# Copy and add to https://github.com/settings/keys
```

### 6. Additional Setup for arrakis (Gaming Desktop)

```bash
# Steam will be available in the applications menu after login
# Login to Steam and enable Proton for Windows games

# For EA/Origin games:
# - Use Heroic launcher (already installed)
# - Or add EA games to Steam as non-Steam games

# Configure GameMode (already installed)
# Games will automatically use GameMode when launched
```

### 7. Additional Setup for urth (Home Server)

```bash
# Wait for k3s to fully start
sudo systemctl status k3s

# Setup kubectl config
mkdir -p ~/.kube
sudo cat /etc/rancher/k3s/k3s.yaml > ~/.kube/config
chmod 600 ~/.kube/config

# Verify k3s is running
kubectl get nodes
kubectl get pods -A

# Deploy your first application
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --port=80 --type=NodePort
kubectl get svc
```

## Host-Specific Configuration

### arrakis (Gaming Desktop)

**Included Features**:
- GNOME desktop environment with GDM
- Steam with Proton support
- Heroic Games Launcher (for Epic/GOG/EA games)
- GameMode for performance optimization
- MangoHud for FPS overlay
- 32-bit library support for games
- Firewall rules for Steam remote play

**GPU Setup**:

Edit `hosts/arrakis/hardware-configuration.nix` and uncomment the appropriate section:

```nix
# For NVIDIA
services.xserver.videoDrivers = [ "nvidia" ];
hardware.nvidia.modesetting.enable = true;

# For AMD
services.xserver.videoDrivers = [ "amdgpu" ];

# For Intel
services.xserver.videoDrivers = [ "intel" ];
```

Then rebuild:
```bash
sudo nixos-rebuild switch --flake .#arrakis
```

### urth (Home Server)

**Included Features**:
- k3s (lightweight Kubernetes)
- Docker with auto-pruning
- Server monitoring tools (htop, btop, iotop)
- Network tools (nmap, tcpdump, iperf3)
- Kubernetes tools (kubectl, helm, k9s)
- SSH server (key-only authentication)
- Optimized kernel parameters for k3s

**k3s Configuration**:

The k3s setup includes:
- API server on port 6443
- Traefik ingress controller disabled (uncomment if needed)
- Flannel VXLAN networking
- Write permissions for kubeconfig (mode 644)

**Managing k3s**:

```bash
# View k3s logs
sudo journalctl -u k3s -f

# Restart k3s
sudo systemctl restart k3s

# Check k3s status
sudo systemctl status k3s

# Access cluster
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
kubectl get nodes
```

## Updating the System

### Update Flake Inputs

```bash
# Update all inputs
nix flake update

# Or update specific input
nix flake lock --update-input nixpkgs
```

### Rebuild

```bash
# For arrakis
sudo nixos-rebuild switch --flake .#arrakis

# For urth
sudo nixos-rebuild switch --flake .#urth
```

### Rollback if Needed

```bash
# List generations
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# Rollback to previous generation
sudo nixos-rebuild switch --rollback
```

## Troubleshooting

### Boot Issues

If system doesn't boot:
1. Boot from NixOS USB again
2. Mount your partitions
3. Check `/mnt/boot/loader/entries/` for boot entries
4. Verify `/mnt/etc/nixos/hardware-configuration.nix` has correct UUIDs

### Network Issues

```bash
# Check network interfaces
ip addr

# For NetworkManager (included in both configs)
nmcli device status
nmcli connection show

# Restart NetworkManager
sudo systemctl restart NetworkManager
```

### GPU Driver Issues (arrakis)

```bash
# Check which GPU is detected
lspci -k | grep -A 3 VGA

# Check loaded kernel modules
lsmod | grep -E "nvidia|amdgpu|i915"

# View Xorg logs
journalctl -u display-manager -b
```

### k3s Issues (urth)

```bash
# Check k3s logs
sudo journalctl -u k3s -n 100

# Verify firewall rules
sudo nft list ruleset | grep -E "6443|8472"

# Check kernel modules
lsmod | grep br_netfilter

# Manually load if needed
sudo modprobe br_netfilter
```

### Docker Issues

```bash
# Check docker status
sudo systemctl status docker

# View docker logs
sudo journalctl -u docker -f

# Test docker
sudo docker run hello-world
```

## Performance Tuning

### For arrakis (Gaming)

```nix
# Add to hosts/arrakis/default.nix
{
  # CPU governor for performance
  powerManagement.cpuFreqGovernor = "performance";

  # Disable power saving on GPU
  services.xserver.deviceSection = ''
    Option "RegistryDwords" "PowerMizerEnable=0x1; PerfLevelSrc=0x2222; PowerMizerLevel=0x3"
  '';
}
```

### For urth (Server)

```nix
# Add to hosts/urth/default.nix
{
  # Automatic garbage collection
  nix.gc = {
    automatic = true;
    dates = "daily";
    options = "--delete-older-than 7d";
  };

  # Optimize store automatically
  nix.optimise = {
    automatic = true;
    dates = [ "daily" ];
  };
}
```

## Getting Help

- **NixOS Manual**: https://nixos.org/manual/nixos/stable/
- **NixOS Wiki**: https://nixos.wiki/
- **NixOS Discourse**: https://discourse.nixos.org/
- **This repo issues**: https://github.com/roshbhatia/sysinit/issues
