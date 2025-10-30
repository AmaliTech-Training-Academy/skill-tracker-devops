# CodeQL Security Analysis Action

A reusable composite action for running CodeQL security analysis on your codebase.

## Features

- ✅ Supports multiple languages (Java, JavaScript, Python, etc.)
- ✅ Configurable query suites (security-only, security-and-quality, etc.)
- ✅ Automatic build detection with CodeQL autobuild
- ✅ Customizable analysis categories for result organization
- ✅ Java version configuration for Java projects

## Usage

### Basic Example

```yaml
jobs:
  security-scan:
    name: CodeQL Security Scan
    runs-on: ubuntu-latest
    permissions:
      actions: read
      contents: read
      security-events: write
    
    steps:
      - name: Checkout devops repository
        uses: actions/checkout@v4

      - name: Run CodeQL Analysis
        uses: ./.github/actions/codeql-analyze
        with:
          repository: myorg/my-backend-repo
          ref: main
          token: ${{ secrets.GITHUB_TOKEN }}
          language: java
```

### Advanced Example

```yaml
jobs:
  codeql-scan:
    name: CodeQL Analysis
    runs-on: ubuntu-latest
    permissions:
      actions: read
      contents: read
      security-events: write
    
    steps:
      - name: Checkout devops repository
        uses: actions/checkout@v4

      - name: Run CodeQL Analysis
        uses: ./.github/actions/codeql-analyze
        with:
          repository: ${{ secrets.BACKEND_REPO_NAME }}
          ref: ${{ github.sha }}
          token: ${{ secrets.PERSONAL_ACCESS_TOKEN }}
          language: java
          queries: security-and-quality
          category: my-custom-category
          java-version: "21"
```

### Multi-Language Example

```yaml
jobs:
  codeql-java:
    name: CodeQL Java Analysis
    runs-on: ubuntu-latest
    permissions:
      security-events: write
    steps:
      - uses: actions/checkout@v4
      - uses: ./.github/actions/codeql-analyze
        with:
          repository: myorg/backend
          ref: main
          token: ${{ secrets.GITHUB_TOKEN }}
          language: java
          category: backend-java

  codeql-javascript:
    name: CodeQL JavaScript Analysis
    runs-on: ubuntu-latest
    permissions:
      security-events: write
    steps:
      - uses: actions/checkout@v4
      - uses: ./.github/actions/codeql-analyze
        with:
          repository: myorg/frontend
          ref: main
          token: ${{ secrets.GITHUB_TOKEN }}
          language: javascript
          category: frontend-js
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `repository` | Repository to checkout (e.g., `owner/repo`) | Yes | - |
| `ref` | Git ref to checkout (commit SHA, branch, or tag) | Yes | - |
| `token` | GitHub token for repository access | Yes | - |
| `language` | Language to analyze (`java`, `javascript`, `python`, etc.) | No | `java` |
| `queries` | CodeQL query suite to run | No | `security-and-quality` |
| `category` | Category for the analysis results | No | `codeql-analysis` |
| `java-version` | Java version to use for analysis | No | `21` |

## Query Suites

- **`security-extended`**: Extended security queries (more comprehensive)
- **`security-and-quality`**: Security + code quality queries (recommended)
- **`security-only`**: Security queries only (faster)

## Supported Languages

- `java`
- `javascript` / `typescript`
- `python`
- `csharp`
- `cpp`
- `go`
- `ruby`

## Permissions Required

The job using this action must have the following permissions:

```yaml
permissions:
  actions: read          # Required to download CodeQL
  contents: read         # Required to checkout code
  security-events: write # Required to upload results
```

## Viewing Results

After the analysis completes, results are available in:

1. **GitHub Security Tab**: `https://github.com/OWNER/REPO/security/code-scanning`
2. **Pull Request Annotations**: Security issues appear as PR comments
3. **Actions Summary**: High-level results in the workflow run summary

## Example Workflow Integration

```yaml
name: Security Scan

on:
  pull_request:
    branches: [main, develop]
  push:
    branches: [main]

jobs:
  codeql:
    name: CodeQL Analysis
    runs-on: ubuntu-latest
    permissions:
      actions: read
      contents: read
      security-events: write
    
    steps:
      - name: Checkout devops repo
        uses: actions/checkout@v4
      
      - name: Run CodeQL
        uses: ./.github/actions/codeql-analyze
        with:
          repository: ${{ github.repository }}
          ref: ${{ github.sha }}
          token: ${{ secrets.GITHUB_TOKEN }}
          language: java
          queries: security-and-quality
```

## Notes

- The action automatically handles repository checkout, so you only need to checkout the devops repository (where the action lives)
- For Java projects, the action sets up the JDK automatically
- CodeQL autobuild works for most projects, but complex builds may require custom build steps
- Analysis results are uploaded to GitHub Security and can trigger PR checks

## Troubleshooting

**Issue**: "No code found to analyze"
- **Solution**: Ensure the repository contains code in the specified language

**Issue**: "Autobuild failed"
- **Solution**: Your project may require custom build steps. Consider using manual build instead of autobuild

**Issue**: "Permission denied"
- **Solution**: Ensure the token has access to the repository and the job has `security-events: write` permission
