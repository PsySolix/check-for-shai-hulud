# NPM Package Vulnerability Scanner

A bash script to detect compromised npm packages in your projects based on the "Shai Hulud" supply chain attack. This tool checks for known malicious packages that were identified in the S1ngularity/Nx attack campaign.

## What It Does

The script scans your Node.js projects for the presence of compromised npm packages. It maintains a comprehensive list of known malicious package versions that were part of the supply chain attack and checks if any of these packages are installed in your project.

The scanner supports:
- **Local project scanning**: Checks packages in the current directory's `package.json` and lock files
- **Multiple package managers**: Automatically detects and works with npm, yarn, and pnpm
- **Two scanning modes**: Exact version matching or package name matching (any version)
- **Global package checking**: Can check globally installed packages (currently disabled by default)

## Features

- 🔍 **Smart Detection**: Automatically detects your package manager (npm, yarn, or pnpm)
- 📦 **Comprehensive Database**: Checks against 400+ known compromised package versions
- ⚡ **Fast Scanning**: Efficient checking with progress indicators
- 🎯 **Two Modes**:
  - Exact version checking (default)
  - Package name checking with `--no-version-check` flag
- 🛡️ **Safe Operation**: Read-only operations, never modifies your project

## Installation

1. Download the script:
   ```bash
   curl -O https://raw.githubusercontent.com/yourusername/yourrepo/main/check-compromised-npm.sh
   ```

2. Make it executable:
   ```bash
   chmod +x check-compromised-npm.sh
   ```

3. Optionally, create an alias for global access (recommended):
   ```bash
   # Add to your shell configuration file (~/.bashrc, ~/.zshrc, etc.)
   alias check-compromised-npm='/path/to/your/check-compromised-npm.sh'

   # Or if you want a shorter alias
   alias vulnscan='/path/to/your/check-compromised-npm.sh'

   # Reload your shell configuration
   source ~/.bashrc  # or source ~/.zshrc
   ```

## Setting Up an Alias (Recommended)

Instead of moving the script to a system directory, it's better to create an alias. This approach is safer, doesn't require administrator privileges, and keeps your script in a location you control.

### For Bash Users

Add the following line to your `~/.bashrc` file:
```bash
echo "alias check-compromised-npm='/path/to/your/check-compromised-npm.sh'" >> ~/.bashrc
source ~/.bashrc
```

### For Zsh Users (macOS default)

Add the following line to your `~/.zshrc` file:
```bash
echo "alias check-compromised-npm='/path/to/your/check-compromised-npm.sh'" >> ~/.zshrc
source ~/.zshrc
```

### Manual Setup

1. Open your shell configuration file in your preferred editor:
   ```bash
   # For bash
   nano ~/.bashrc

   # For zsh (macOS)
   nano ~/.zshrc
   ```

2. Add the alias line:
   ```bash
   alias check-compromised-npm='/full/path/to/your/check-compromised-npm.sh'
   ```

3. Save the file and reload your shell configuration:
   ```bash
   source ~/.bashrc  # or source ~/.zshrc
   ```

### Verify the Alias

Test that your alias works:
```bash
check-compromised-npm --help
```

### Suggested Alias Names

- `check-compromised-npm` - Clear and descriptive
- `vulnscan` - Short and memorable
- `npm-security-check` - Descriptive alternative
- `shai-hulud-check` - References the attack name

## Usage

### Basic Usage

Navigate to your Node.js project directory and run:

```bash
./check-compromised-npm.sh
```

### Command Line Options

```bash
./check-compromised-npm.sh [OPTIONS]

Options:
  --no-version-check    Check if package exists (any version) instead of exact version
  -h, --help           Show help message
```

### Examples

**Check for exact vulnerable versions:**
```bash
./check-compromised-npm.sh
```

**Check for package presence (any version):**
```bash
./check-compromised-npm.sh --no-version-check
```

## Batch Scanning Multiple Projects

To scan multiple projects at once, you can use a simple loop. This is particularly useful if you have multiple Node.js projects in subdirectories.

### Example: Scan All Subdirectories (Sequential)

```bash
for dir in */; do
  if [ -d "$dir" ]; then
    echo "Running vulnerability scan in: $dir"
    cd "$dir"
    check-compromised-npm --no-version-check
    cd ..
    echo "---"
  fi
done
```

### Example: Scan All Subdirectories (Parallel)

To run scans in parallel for faster execution, you can use background processes. **Important:** When running in parallel, output from multiple processes can interleave, causing progress indicators to jump around. The examples below prevent this by redirecting each scan's output to separate log files or using output buffering.

**Why output interleaving happens:** The script uses carriage return (`\r`) to update progress on the same line. When multiple processes write simultaneously, their output gets mixed together.

This example limits concurrent jobs to 4 and prevents output interleaving by redirecting each scan's output to a separate log file:

```bash
#!/bin/bash
# Maximum number of concurrent jobs
MAX_JOBS=4

# Disable history expansion in zsh (prevents "event not found" error)
set +H 2>/dev/null || true

# Set the script path - UPDATE THIS to your actual script location
# Option 1: Use full path
SCRIPT_PATH="../scripts/check-for-shai-hulud/check-compromised-npm.sh"
# Option 2: If installed via symlink in PATH
# SCRIPT_PATH="$(which check-compromised-npm.sh)"
# Option 3: Relative to current directory
# SCRIPT_PATH="./check-compromised-npm.sh"

# Track background job PIDs for cleanup
declare -a JOB_PIDS=()

# Cleanup function to kill all background jobs on exit
cleanup() {
  echo ""
  echo "Interrupted! Stopping all scans..."
  for pid in "${JOB_PIDS[@]}"; do
    if kill -0 "$pid" 2>/dev/null; then
      kill "$pid" 2>/dev/null
    fi
  done
  # Also kill any remaining check-compromised-npm processes
  pkill -f "check-compromised-npm" 2>/dev/null
  wait
  echo "All scans stopped."
  exit 130
}

# Set up signal handlers
trap cleanup SIGINT SIGTERM

# Function to wait for a job slot
wait_for_job_slot() {
  while [ $(jobs -r | wc -l) -ge $MAX_JOBS ]; do
    sleep 0.1
  done
}

# Create logs directory for scan results
mkdir -p scan_logs

for dir in */; do
  if [ -d "$dir" ]; then
    wait_for_job_slot

    # Run scan in background with output redirected to log file
    (
      dirname=$(basename "$dir")
      logfile="scan_logs/${dirname}.log"
      echo "[$(date '+%H:%M:%S')] Starting scan: $dirname" | tee "$logfile"
      cd "$dir"
      "$SCRIPT_PATH" --no-version-check >> "../$logfile" 2>&1
      echo "[$(date '+%H:%M:%S')] Completed scan: $dirname" | tee -a "../$logfile"
    ) &

    # Store the PID
    last_pid=$!
    JOB_PIDS+=($last_pid)
  fi
done

# Wait for all background jobs to complete
wait
echo ""
echo "All scans completed! Check scan_logs/ directory for individual results."
echo "Summary:"
for logfile in scan_logs/*.log; do
  if [ -f "$logfile" ]; then
    dirname=$(basename "$logfile" .log)
    if grep -q "WARNING: Found" "$logfile"; then
      echo "  ⚠️  $dirname: Vulnerabilities found (see $logfile)"
    else
      echo "  ✅ $dirname: No vulnerabilities found"
    fi
  fi
done
```

**Important:** Update the `SCRIPT_PATH` variable at the top to point to your actual script location.

**Alternative: Use alias with expansion enabled**

If you want to use your alias, you need to enable alias expansion in subshells:

```bash
#!/bin/bash
# Maximum number of concurrent jobs
MAX_JOBS=4

# Disable history expansion in zsh
set +H 2>/dev/null || true

# Enable alias expansion in non-interactive shells
shopt -s expand_aliases 2>/dev/null || true

# Define or source your alias
alias check-compromised-npm='/path/to/your/check-compromised-npm.sh'
# Or source your profile where the alias is defined
# source ~/.bashrc  # or ~/.zshrc

# Track background job PIDs for cleanup
declare -a JOB_PIDS=()

# Cleanup function to kill all background jobs on exit
cleanup() {
  echo ""
  echo "Interrupted! Stopping all scans..."
  for pid in "${JOB_PIDS[@]}"; do
    if kill -0 "$pid" 2>/dev/null; then
      kill "$pid" 2>/dev/null
    fi
  done
  pkill -f "check-compromised-npm" 2>/dev/null
  wait
  echo "All scans stopped."
  exit 130
}

trap cleanup SIGINT SIGTERM

wait_for_job_slot() {
  while [ $(jobs -r | wc -l) -ge $MAX_JOBS ]; do
    sleep 0.1
  done
}

mkdir -p scan_logs

for dir in */; do
  if [ -d "$dir" ]; then
    wait_for_job_slot

    (
      dirname=$(basename "$dir")
      logfile="scan_logs/${dirname}.log"
      echo "[$(date '+%H:%M:%S')] Starting scan: $dirname" | tee "$logfile"
      cd "$dir"
      check-compromised-npm --no-version-check >> "../$logfile" 2>&1
      echo "[$(date '+%H:%M:%S')] Completed scan: $dirname" | tee -a "../$logfile"
    ) &

    last_pid=$!
    JOB_PIDS+=($last_pid)
  fi
done

wait
echo ""
echo "All scans completed! Check scan_logs/ directory for individual results."
echo "Summary:"
for logfile in scan_logs/*.log; do
  if [ -f "$logfile" ]; then
    dirname=$(basename "$logfile" .log)
    if grep -q "WARNING: Found" "$logfile"; then
      echo "  ⚠️  $dirname: Vulnerabilities found (see $logfile)"
    else
      echo "  ✅ $dirname: No vulnerabilities found"
    fi
  fi
done
```

**Note:** Both versions handle Ctrl+C properly by trapping signals and cleaning up all background jobs when interrupted.

**Alternative: Real-time output with mutex (prevents interleaving)**

If you prefer to see output in real-time without log files, you can use a simple mutex mechanism:

```bash
#!/bin/bash
MAX_JOBS=4
LOCKFILE="/tmp/scan_output.lock"

# Disable history expansion in zsh
set +H 2>/dev/null || true

# Cleanup on exit
trap 'rm -f "$LOCKFILE"; pkill -f "check-compromised-npm" 2>/dev/null' EXIT INT TERM

wait_for_job_slot() {
  while [ $(jobs -r | wc -l) -ge $MAX_JOBS ]; do
    sleep 0.1
  done
}

# Function to safely output (prevents interleaving)
safe_echo() {
  (
    flock -n 9 || exit 1
    echo "$@"
  ) 9>"$LOCKFILE"
}

for dir in */; do
  if [ -d "$dir" ]; then
    wait_for_job_slot

    # Run scan in background
    (
      safe_echo "=== Starting scan: $dir ==="
      cd "$dir"
      # Capture output and print atomically
      output=$(check-compromised-npm --no-version-check 2>&1)
      safe_echo "$output"
      safe_echo "=== Completed scan: $dir ==="
    ) &
  fi
done

wait
rm -f "$LOCKFILE"
echo "All scans completed!"
```

**Adjust `MAX_JOBS`** based on your system's capabilities (CPU cores, memory). Common values:
- `MAX_JOBS=4` - Conservative, good for most systems
- `MAX_JOBS=8` - For systems with more resources
- `MAX_JOBS=$(nproc)` - Use all CPU cores (Linux)
- `MAX_JOBS=$(sysctl -n hw.ncpu)` - Use all CPU cores (macOS)

**Note:** Each directory is scanned independently, so there's no risk of directory collisions. Each background process changes into its own directory.

### Summarizing Scan Results

After running parallel scans with log files, you can summarize the results at any time:

**Quick Summary Command:**

```bash
#!/bin/bash
# Quick summary of scan results in scan_logs/

echo "=== Vulnerability Scan Summary ==="
echo ""

if [ ! -d "scan_logs" ] || [ -z "$(ls -A scan_logs 2>/dev/null)" ]; then
  echo "No scan logs found. Run a scan first."
  exit 0
fi

total=0
vulnerable=0
clean=0
skipped=0

for logfile in scan_logs/*.log; do
  if [ -f "$logfile" ]; then
    dirname=$(basename "$logfile" .log)
    total=$((total + 1))

    if grep -q "WARNING: Found" "$logfile"; then
      vulnerable=$((vulnerable + 1))
      count=$(grep -c "WARNING: Found" "$logfile")
      echo "  ⚠️  $dirname: $count vulnerable package(s) found"
    elif grep -q "No package.json found" "$logfile"; then
      skipped=$((skipped + 1))
      # Don't show in list, only count
    elif grep -q "scan complete" "$logfile"; then
      clean=$((clean + 1))
      echo "  ✅ $dirname: Clean"
    else
      skipped=$((skipped + 1))
      # Don't show in list, only count
    fi
  fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Total: $total | Clean: $clean | Vulnerable: $vulnerable | Skipped: $skipped"

if [ $vulnerable -gt 0 ]; then
  echo ""
  echo "⚠️  Action required: $vulnerable director$([ $vulnerable -eq 1 ] && echo "y has" || echo "ies have") vulnerabilities"
  echo "Review logs in scan_logs/ directory for details."
fi
```

**Detailed Summary with Vulnerability List:**

```bash
#!/bin/bash
# Detailed summary showing which packages are vulnerable

echo "=== Detailed Vulnerability Scan Summary ==="
echo ""

if [ ! -d "scan_logs" ] || [ -z "$(ls -A scan_logs 2>/dev/null)" ]; then
  echo "No scan logs found. Run a scan first."
  exit 0
fi

for logfile in scan_logs/*.log; do
  if [ -f "$logfile" ]; then
    dirname=$(basename "$logfile" .log)

    if grep -q "WARNING: Found" "$logfile"; then
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo "⚠️  $dirname"
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      grep "WARNING: Found" "$logfile" | sed 's/^/  /'
      echo ""
    fi
  fi
done

# Overall stats
total=$(find scan_logs -name "*.log" -type f | wc -l | tr -d ' ')
vulnerable=$(grep -l "WARNING: Found" scan_logs/*.log 2>/dev/null | wc -l | tr -d ' ')
clean=$((total - vulnerable))

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Summary: $vulnerable vulnerable / $total total"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
```

**Save as a script:**

You can save the quick summary as a reusable script:

```bash
# Create the summary script
cat > summarize-scans.sh << 'EOF'
#!/bin/bash
# Summarize vulnerability scan results

echo "=== Vulnerability Scan Summary ==="
echo ""

if [ ! -d "scan_logs" ] || [ -z "$(ls -A scan_logs 2>/dev/null)" ]; then
  echo "No scan logs found in current directory."
  echo "Make sure you're in the directory where you ran the scans."
  exit 0
fi

total=0
vulnerable=0
clean=0
skipped=0

for logfile in scan_logs/*.log; do
  if [ -f "$logfile" ]; then
    dirname=$(basename "$logfile" .log)
    total=$((total + 1))

    if grep -q "WARNING: Found" "$logfile"; then
      vulnerable=$((vulnerable + 1))
      count=$(grep -c "WARNING: Found" "$logfile")
      echo "  ⚠️  $dirname: $count vulnerable package(s) found"
    elif grep -q "No package.json found" "$logfile"; then
      skipped=$((skipped + 1))
      # Don't show in list, only count
    elif grep -q "scan complete" "$logfile"; then
      clean=$((clean + 1))
      echo "  ✅ $dirname: Clean"
    else
      skipped=$((skipped + 1))
      # Don't show in list, only count
    fi
  fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Total: $total | Clean: $clean | Vulnerable: $vulnerable | Skipped: $skipped"

if [ $vulnerable -gt 0 ]; then
  echo ""
  echo "⚠️  Action required: $vulnerable director$([ $vulnerable -eq 1 ] && echo "y has" || echo "ies have") vulnerabilities"
  echo "Review logs in scan_logs/ directory for details."
  echo ""
  echo "To see detailed vulnerable packages, run:"
  echo "  grep 'WARNING: Found' scan_logs/*.log"
fi
EOF

chmod +x summarize-scans.sh

# Then run it anytime:
./summarize-scans.sh
```

**⚠️ Stopping a Running Parallel Scan:**

If you need to stop a running parallel scan, Ctrl+C alone won't work because it only stops the foreground process, not the background jobs. Use one of these methods:

**Option 1: Kill all background jobs (quickest)**
```bash
# In the same terminal, press Ctrl+C once, then immediately run:
killall check-compromised-npm.sh  # or killall check-compromised-npm if using alias
jobs -p | xargs kill 2>/dev/null  # Kill all background jobs
```

**Option 2: Find and kill processes**
```bash
# Find the process IDs
ps aux | grep check-compromised-npm

# Kill them (replace PID with actual process IDs)
kill <PID1> <PID2> <PID3> ...

# Or kill all at once
pkill -f check-compromised-npm
```

**Option 3: Kill the parent shell**
```bash
# Find the shell process running the script
ps aux | grep "for dir"

# Kill it (this will terminate all child processes)
kill <SHELL_PID>
```

**Option 4: Use a new terminal**
```bash
# In a new terminal, find and kill all related processes
pkill -f "check-compromised-npm"
pkill -f "check-for-shai-hulud"
```

### Example: Parallel Scanning with GNU Parallel (Alternative)

If you have GNU `parallel` installed, you can use this more elegant approach. GNU parallel automatically handles output buffering to prevent interleaving:

```bash
# Install GNU parallel: brew install parallel (macOS) or apt-get install parallel (Linux)

# Scan all directories in parallel with proper output handling
mkdir -p scan_logs
ls -d */ | parallel -j 4 --tag 'cd {} && echo "Scanning: {}" && check-compromised-npm --no-version-check' > scan_logs/parallel_scan.log 2>&1

# Or with individual log files per directory
ls -d */ | parallel -j 4 'cd {} && check-compromised-npm --no-version-check > ../scan_logs/{/}.log 2>&1 && echo "Completed: {}"'

# Or scan only directories with package.json
ls -d */ | parallel -j 4 'if [ -f "{}/package.json" ]; then cd {} && check-compromised-npm --no-version-check > ../scan_logs/{/}.log 2>&1 && echo "Completed: {}"; fi'
```

**Note:**
- The `-j 4` flag limits to 4 concurrent jobs. Remove it to use one job per CPU core, or set a different number.
- The `--tag` option prefixes each line with the job identifier, making it easier to track which directory produced which output.
- Output redirection prevents interleaving of progress indicators.

### Example: Scan Specific Project Types

```bash
# Scan only directories that contain package.json
for dir in */; do
  if [ -d "$dir" ] && [ -f "$dir/package.json" ]; then
    echo "Scanning Node.js project: $dir"
    cd "$dir"
    check-compromised-npm
    cd ..
    echo "---"
  fi
done
```

### Example: Scan with Direct Script Path

If you prefer not to use an alias, you can still use the direct path:

```bash
for dir in */; do
  if [ -d "$dir" ]; then
    echo "Running vulnerability scan in: $dir"
    cd "$dir"
    /path/to/your/check-compromised-npm.sh --no-version-check
    cd ..
    echo "---"
  fi
done
```

## Understanding the Output

### Normal Operation
```
Checking in current project: /path/to/your/project
Detected package manager: npm
Mode: Checking for exact vulnerable versions
Scanning 464 known compromised packages...
Progress: 464/464 packages checked
Project scan complete. Found 0 compromised packages.
```

### When Vulnerabilities Are Found
```
WARNING: Found compromised version in project: @ctrl/tinycolor@4.1.1
WARNING: Found package in project: ngx-bootstrap (potentially vulnerable - check version manually)
```

## Scanning Modes

### Exact Version Mode (Default)
- Checks for specific vulnerable versions
- More precise but may miss newer vulnerable versions
- Recommended for security-critical environments

### Package Name Mode (`--no-version-check`)
- Checks if any version of a known vulnerable package is installed
- Less precise but catches more potential issues
- Useful for general auditing and when you want to manually verify versions

## Requirements

- Bash shell
- One of: npm, yarn, or pnpm installed
- Node.js project with `package.json`

## What Packages Are Checked

The script checks for packages that were part of the "Shai Hulud" supply chain attack, including but not limited to:

- `@crowdstrike/*` packages
- `@ctrl/*` packages
- `@nativescript-community/*` packages
- `@operato/*` packages
- Various Angular, React, and other framework-specific packages
- Development tools and utilities

The complete list includes over 400 specific package versions that were confirmed to be compromised.

## Security Notes

- This script only **detects** compromised packages, it does not remove them
- If vulnerabilities are found, manually review and update/remove the affected packages
- Keep your dependencies updated and use `npm audit` or equivalent tools regularly
- Consider using package-lock files to ensure reproducible builds

## Troubleshooting

### "No package.json found"
- Ensure you're running the script in a directory that contains a Node.js project
- Check that the `package.json` file exists and is readable

### Permission Denied
- Make sure the script has execute permissions: `chmod +x check-compromised-npm.sh`

### Package Manager Not Detected
- The script defaults to npm if it cannot detect your package manager
- Ensure your lock file is present (`package-lock.json`, `yarn.lock`, or `pnpm-lock.yaml`)

## Contributing

To update the list of vulnerable packages, modify the `VULNS` array in the script. Each entry should be in the format `"package@version"`.

## License

This script is provided as-is for security scanning purposes. Use at your own discretion.

## Disclaimer

This tool is based on publicly available information about the "Shai Hulud" supply chain attack. While we strive to keep the vulnerability database current, always verify findings and consult additional security resources for comprehensive protection.
