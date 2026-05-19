# Architecture Overview

This project uses two separate AWS EC2 instances to keep the CI/CD workload
isolated from the monitoring stack.

## Instance 1 - DevSecOps Server

- OS: Ubuntu 24.04
- Type: m7i-flex.large
- Hosts: Jenkins, Docker, SonarQube, Trivy, OWASP, Netflix App

## Instance 2 - Monitoring Server

- OS: Ubuntu 24.04
- Type: m7i-flex.large
- Hosts: Prometheus, Grafana, Node Exporter

## Why Two Instances

Running Prometheus and Grafana on the same server as Jenkins creates
resource contention. A dedicated monitoring server ensures that even if
the Jenkins server is under heavy load during a pipeline run, the
monitoring and alerting layer stays healthy and accurate.

## Port Reference

| Service       | Port |
|---------------|------|
| Jenkins       | 8080 |
| SonarQube     | 9000 |
| Prometheus    | 9090 |
| Grafana       | 3000 |
| Node Exporter | 9100 |
| Netflix App   | 8081 |

## Data Flow

1. Developer pushes code to GitHub
2. Jenkins picks up the change and triggers the pipeline
3. SonarQube analyzes code quality and reports back via webhook
4. OWASP scans dependencies for known CVEs
5. Trivy scans the filesystem and the final Docker image
6. Docker image is built with the TMDB API key injected securely
7. Image is pushed to DockerHub
8. Container is deployed and accessible on port 8081
9. Prometheus scrapes Jenkins metrics continuously
10. Grafana visualizes everything on pre-built dashboards
11. Email notification is sent with build result and scan reports attached
