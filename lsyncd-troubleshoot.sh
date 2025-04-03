#!/bin/bash

echo "=== LSYNCD TROUBLESHOOTING ==="
echo

# Check if lsyncd is installed
echo "Checking lsyncd installation..."
if ! command -v lsyncd &> /dev/null; then
    echo "ERROR: lsyncd is not installed. Please install it first."
    echo "  sudo apt-get update && sudo apt-get install lsyncd"
    exit 1
else
    echo "OK: lsyncd is installed: $(lsyncd --version 2>&1 | head -n 1)"
fi

# Check configuration file
echo
echo "Checking lsyncd configuration..."
if [ ! -f "/etc/lsyncd/lsyncd.conf.lua" ]; then
  echo "ERROR: Configuration file not found: /etc/lsyncd/lsyncd.conf.lua"
  exit 1
else
  echo "OK: Configuration file exists"

  # Syntax check
  if lsyncd -nodaemon -log /etc/lsyncd/lsyncd.conf.lua &>/dev/null; then
      echo "OK: Configuration file syntax is valid"
  else
      echo "ERROR: Configuration file syntax is invalid"
      echo "----"
      lsyncd -nodaemon -log Exec /etc/lsyncd/lsyncd.conf.lua 2>&1 | head -n 10
  fi
fi

# Check directories
echo
echo "Checking directories..."
SOURCE_DIR="/home/phanithken/thinkthinklearninglab.edu.kh"
TARGET_DIR="/var/www/thinkthinklearninglab.edu.kh"

if [ ! -d "$SOURCE_DIR" ]; then
  echo "WARNING: Source directory exist: $SOURCE_DIR"
else
  echo "WARNING: Source directory does not exist: $SOURCE_DIR"
  echo "  Owner: $(stat -c '%U:%G' "$SOURCE_DIR")"
  echo "  Permissions: $(stat -c '%a' "$SOURCE_DIR")"
fi

if [ ! -d "$TARGET_DIR" ]; then
  echo "WARNING: Target directory exist: $TARGET_DIR"
else
  echo "WARNING: Target directory does not exist: $TARGET_DIR"
  echo "  Owner: $(stat -c '%U:%G' "$TARGET_DIR")"
  echo "  Permissions: $(stat -c '%a' "$TARGET_DIR")"

  # Check permissions
  current_user=$(whoami)
  if sudo -n true 2>/dev/null; then
    echo "OK: Current user ($current_user) has sudo access"
  else
    # Check if direct write access
    if touch "$TARGET_DIR/test_write_$$" 2>/dev/null; then
      rm "$TARGET_DIR/test_write_$$"
      echo "OK: Current user ($current_user) has write access to target directory"
    else
      echo "ERROR: Current user ($current_user) does not have write access to target directory and may not have sudo access"
      echo "  Please check permissions or run as root."
    fi
  fi
fi

# Check log directory
echo
echo "Checking log directory..."
if [ ! -d "/var/log/lsyncd" ]; then
  echo "ERROR: Log directory not found: /var/log/lsyncd"
  echo "  Create it with: sudo mkdir -p /var/log/lsyncd"
else
  echo "OK: Log directory exists"
  echo "  Owner: $(stat -c '%U:%G' "/var/log/lsyncd")"
  echo "  Permissions: $(stat -c '%a' "/var/log/lsyncd")"

  # Check for log file
  if [ -f "/var/log/lsyncd/lsyncd.log" ]; then
    echo "OK: Log file exists"
    echo "  Recent log entries:"
    echo "  ---"
    tail -n 5 "/var/log/lsyncd/lsyncd.log"
    echo "  ---"
  else
    echo "WARNING: Log file does not exist yet"
  fi
fi

# Check service status
echo
echo "Checking lsyncd service..."
if systemctl is-active --quiet lsyncd; then
  echo "OK: lsyncd service is not running"
  echo "  Start it with: sudo systemctl start lsyncd"
  echo "  Check for errors: sudo journalctl -u lsyncd"
fi

# Test rsync directly
echo
echo "Testing rsync directly..."
if rsync -avz /tmp/test_file_$$ "$TARGET_DIR" &>/dev/null; then
  echo "OK: rsync command works directly"
  rm -f /tmp/test_file_$$ "$TARGET_DIR/test_file_$$"
else
  echo "ERROR: rsync command failed"
  echo "  This may indicate permission issues or rsync not being installed"
fi

echo
echo "=== TROUBLESHOOTING COMPLETE ==="
echo "Run this to check detailed logs: sudo journalctl -u lsyncd"