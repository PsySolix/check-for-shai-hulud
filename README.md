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

### Example: Scan All Subdirectories

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
