# Trivy Container Security Scan Action

A reusable composite action for scanning Docker images for vulnerabilities using Trivy.

## Features

- ✅ Scans Docker images for security vulnerabilities
- ✅ Configurable severity levels (CRITICAL, HIGH, MEDIUM, LOW)
- ✅ Multiple output formats (table, json, sarif)
- ✅ Optional exit on vulnerabilities found
- ✅ Fast and lightweight
- ✅ No external dependencies or API keys required

## Usage

### Basic Example

```yaml
jobs:
  security-scan:
    runs-on: ubuntu-latest
    steps:
      - name: Build Docker image
        run: docker build -t myapp:latest .

      - name: Scan image with Trivy
        uses: ./.github/actions/trivy-scan
        with:
          image: myapp:latest
```

### Advanced Example

```yaml
jobs:
  build-and-scan:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Build image
        run: docker build -t myregistry/myapp:${{ github.sha }} .

      - name: Scan for critical vulnerabilities
        uses: ./.github/actions/trivy-scan
        with:
          image: myregistry/myapp:${{ github.sha }}
          severity: CRITICAL
          exit-code: "1"  # Fail build if critical vulnerabilities found
          format: json
          output-file: trivy-results.json

      - name: Upload scan results
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: trivy-scan-results
          path: trivy-results.json
```

### Scan Multiple Images

```yaml
jobs:
  scan-services:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        service: [api, frontend, worker]
    steps:
      - name: Build ${{ matrix.service }}
        run: docker build -t ${{ matrix.service }}:latest ./${{ matrix.service }}

      - name: Scan ${{ matrix.service }}
        uses: ./.github/actions/trivy-scan
        with:
          image: ${{ matrix.service }}:latest
          severity: CRITICAL,HIGH
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `image` | Docker image to scan (e.g., `registry/repo:tag`) | Yes | - |
| `severity` | Severities to scan for (comma-separated) | No | `CRITICAL,HIGH` |
| `exit-code` | Exit code when vulnerabilities found (`0` or `1`) | No | `0` |
| `format` | Output format (`table`, `json`, `sarif`) | No | `table` |
| `output-file` | Output file path (optional) | No | `""` |

## Outputs

| Output | Description |
|--------|-------------|
| `scan-result` | Scan result (`passed` or `failed`) |

## Severity Levels

- **CRITICAL**: Critical vulnerabilities that require immediate attention
- **HIGH**: High-severity vulnerabilities
- **MEDIUM**: Medium-severity vulnerabilities
- **LOW**: Low-severity vulnerabilities
- **UNKNOWN**: Vulnerabilities with unknown severity

You can combine multiple levels: `CRITICAL,HIGH,MEDIUM`

## Exit Codes

- **`exit-code: "0"`** (default): Always succeed, just report vulnerabilities
  - Use for informational scanning
  - Won't block deployment
  
- **`exit-code: "1"`**: Fail if vulnerabilities found
  - Use to enforce security policies
  - Blocks deployment on vulnerabilities

## Output Formats

### Table (Default)
Human-readable table format in console output.

### JSON
Machine-readable JSON format for processing or storage.

```yaml
- uses: ./.github/actions/trivy-scan
  with:
    image: myapp:latest
    format: json
    output-file: scan-results.json
```

### SARIF
Security Alert Results Interchange Format for GitHub Security tab.

```yaml
- uses: ./.github/actions/trivy-scan
  with:
    image: myapp:latest
    format: sarif
    output-file: trivy-results.sarif

- name: Upload to GitHub Security
  uses: github/codeql-action/upload-sarif@v3
  with:
    sarif_file: trivy-results.sarif
```

## Examples

### Informational Scan (Don't Block)

```yaml
- name: Security scan (informational)
  uses: ./.github/actions/trivy-scan
  with:
    image: myapp:${{ github.sha }}
    severity: CRITICAL,HIGH,MEDIUM
    exit-code: "0"
```

### Enforce Security Policy (Block on Critical)

```yaml
- name: Security scan (enforce)
  uses: ./.github/actions/trivy-scan
  with:
    image: myapp:${{ github.sha }}
    severity: CRITICAL
    exit-code: "1"
```

### Scan and Upload Results

```yaml
- name: Scan image
  uses: ./.github/actions/trivy-scan
  with:
    image: myapp:latest
    format: sarif
    output-file: trivy-results.sarif

- name: Upload SARIF to GitHub Security
  uses: github/codeql-action/upload-sarif@v3
  if: always()
  with:
    sarif_file: trivy-results.sarif
```

## Integration with CI/CD

### After Build, Before Push

```yaml
- name: Build image
  run: docker build -t myapp:latest .

- name: Scan image
  uses: ./.github/actions/trivy-scan
  with:
    image: myapp:latest
    exit-code: "1"  # Block push if vulnerabilities found

- name: Push image
  run: docker push myapp:latest
```

### Scan ECR Images

```yaml
- name: Login to ECR
  uses: aws-actions/amazon-ecr-login@v2

- name: Build and push
  run: |
    docker build -t $ECR_REGISTRY/myapp:$TAG .
    docker push $ECR_REGISTRY/myapp:$TAG

- name: Scan ECR image
  uses: ./.github/actions/trivy-scan
  with:
    image: ${{ env.ECR_REGISTRY }}/myapp:${{ env.TAG }}
```

## Comparison with CodeQL

| Feature | Trivy | CodeQL |
|---------|-------|--------|
| **Scan Target** | Container images | Source code |
| **Speed** | ⚡ Fast (seconds) | 🐌 Slow (minutes) |
| **Setup** | ✅ Simple | ❌ Complex |
| **Dependencies** | ✅ None | ❌ Requires build |
| **Cross-repo** | ✅ Easy | ❌ Complex |
| **Results** | Immediate | Delayed upload |
| **Best For** | Container security | Code quality |

## Notes

- Trivy automatically downloads vulnerability database on first run
- Database is cached for subsequent scans
- Scans are performed locally, no data sent to external services
- Works with any Docker registry (ECR, Docker Hub, GCR, etc.)
- No authentication required for Trivy itself (only for pulling images)

## Troubleshooting

**Issue**: "Failed to pull image"
- **Solution**: Ensure you're logged into the registry before scanning

**Issue**: "Database download failed"
- **Solution**: Check internet connectivity, Trivy needs to download vulnerability DB

**Issue**: "Too many vulnerabilities found"
- **Solution**: Use `ignore-unfixed: true` to ignore vulnerabilities without fixes

## Resources

- [Trivy Documentation](https://aquasecurity.github.io/trivy/)
- [Trivy GitHub Action](https://github.com/aquasecurity/trivy-action)
- [Vulnerability Database](https://github.com/aquasecurity/trivy-db)
