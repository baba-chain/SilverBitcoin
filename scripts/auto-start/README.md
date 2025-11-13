# Auto-Start Service Setup

## What This Does

- ✅ Automatically starts all 24 validator nodes after server reboots
- ✅ Creates a systemd service that manages your nodes
- ✅ Ensures your nodes restart if they crash
- ✅ Optional health check timer (monitors nodes every 10 minutes)

## Prerequisites

- Ubuntu 24.04 LTS (or compatible Linux with systemd)
- Nodes must be initialized and working properly
- Run `./troubleshoot.sh` to verify system is ready

## Files in this folder

### For Ubuntu 24.04 (NEW - Recommended)
- `setup-autostart-ubuntu.sh` - **Ubuntu 24.04 systemd service setup**
- `remove-autostart.sh` - Remove auto-start service
- `UBUNTU-AUTOSTART-GUIDE.md` - Complete Ubuntu setup guide

### Legacy (Old validator/RPC setup)
- `AUTO_START_SERVICE_GUIDE.md` - Old guide (for reference)
- `create-autostart-service.sh` - Old script (deprecated)

## Quick Start (Ubuntu 24.04)

### 1. Make sure nodes work
```bash
# Test that nodes start properly
./start-all-nodes.sh
./node-status.sh

# If working, stop them
./stop-all-nodes.sh
```

### 2. Setup auto-start service
```bash
cd auto-start
sudo ./setup-autostart-ubuntu.sh
```

The script will:
- Detect your SilverBitcoin directory
- Create systemd service
- Enable auto-start on boot
- Optionally create health check timer
- Ask if you want to start now

### 3. Test the service
```bash
# Check status
sudo systemctl status silverbitcoin-nodes

# View logs
sudo journalctl -u silverbitcoin-nodes -f

# Test reboot
sudo reboot
```

## Service Management

After setup, manage your nodes with systemd:

```bash
# Start all nodes
sudo systemctl start silverbitcoin-nodes

# Stop all nodes
sudo systemctl stop silverbitcoin-nodes

# Restart all nodes
sudo systemctl restart silverbitcoin-nodes

# Check status
sudo systemctl status silverbitcoin-nodes

# View real-time logs
sudo journalctl -u silverbitcoin-nodes -f

# View last 50 log lines
sudo journalctl -u silverbitcoin-nodes -n 50

# Disable auto-start
sudo systemctl disable silverbitcoin-nodes

# Enable auto-start
sudo systemctl enable silverbitcoin-nodes
```

## Health Check Timer (Optional)

If you enabled the health check timer during setup:

```bash
# Check timer status
sudo systemctl status silverbitcoin-healthcheck.timer

# View health check logs
sudo journalctl -u silverbitcoin-healthcheck -f

# Disable health checks
sudo systemctl disable silverbitcoin-healthcheck.timer
sudo systemctl stop silverbitcoin-healthcheck.timer
```

## Remove Auto-Start

To remove the auto-start service:

```bash
cd auto-start
sudo ./remove-autostart.sh
```

This will:
- Stop the service
- Disable auto-start
- Remove service files
- Keep your nodes intact (just not auto-starting)

## Features

### Main Service
- **Auto-start on boot**: Nodes start automatically after reboot
- **Network wait**: Waits 10 seconds for network to be ready
- **Failure recovery**: Restarts automatically if service fails
- **Resource limits**: Proper file descriptor and process limits
- **Logging**: All output goes to systemd journal

### Health Check Timer (Optional)
- **Periodic monitoring**: Checks every 10 minutes
- **Auto-recovery**: Restarts service if too few nodes running
- **Logging**: Health check results in journal

## Troubleshooting

### Service won't start
```bash
# Check logs for errors
sudo journalctl -u silverbitcoin-nodes -n 50

# Check service status
sudo systemctl status silverbitcoin-nodes

# Try manual start
sudo systemctl start silverbitcoin-nodes
```

### Nodes not starting after reboot
```bash
# Check if service is enabled
sudo systemctl is-enabled silverbitcoin-nodes

# Check if service started
sudo systemctl status silverbitcoin-nodes

# View boot logs
sudo journalctl -u silverbitcoin-nodes -b
```

### Service shows "failed"
```bash
# Check what went wrong
sudo journalctl -u silverbitcoin-nodes -n 100

# Common issues:
# - Geth binary not found
# - Nodes not initialized
# - Permission issues
# - Network not ready (increase wait time)
```

## This is Optional

Auto-start is a **convenience feature**. Your nodes will work fine without it - you'll just need to manually start them after server reboots using `./start-all-nodes.sh`.

## System Requirements

- Ubuntu 24.04 LTS (or compatible)
- systemd (standard on Ubuntu)
- Root/sudo access
- Nodes already initialized and tested
