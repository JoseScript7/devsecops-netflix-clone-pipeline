<div align="center">

# DevSecOps: Netflix Clone CI/CD Pipeline with Monitoring

![License](https://img.shields.io/badge/License-MIT-yellow.svg)
![Jenkins](https://img.shields.io/badge/Jenkins-2.504.1-D24939?logo=jenkins&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-Latest-2496ED?logo=docker&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-EC2-FF9900?logo=amazonaws&logoColor=white)
![SonarQube](https://img.shields.io/badge/SonarQube-LTS-4E9BCD?logo=sonarqube&logoColor=white)
![Trivy](https://img.shields.io/badge/Trivy-Security-1904DA?logo=aquasecurity&logoColor=white)
![Prometheus](https://img.shields.io/badge/Prometheus-2.47.1-E6522C?logo=prometheus&logoColor=white)
![Grafana](https://img.shields.io/badge/Grafana-Latest-F46800?logo=grafana&logoColor=white)

A complete end-to-end DevSecOps CI/CD pipeline for a Netflix Clone application — covering infrastructure provisioning, security scanning, containerization, monitoring, and automated deployment.

</div>

---

## Table of Contents

- [Project Overview](#-project-overview)
- [Architecture](#-architecture)
- [Tools & Technologies](#-tools--technologies)
- [Port Reference](#-port-reference)
- [Step 1 — Launch EC2 Instances](#step-1--launch-ec2-instances)
- [Step 2 — Install Jenkins](#step-2--install-jenkins)
- [Step 3 — Install Docker](#step-3--install-docker)
- [Step 4 — Deploy SonarQube](#step-4--deploy-sonarqube)
- [Step 5 — Install Trivy](#step-5--install-trivy)
- [Step 6 — Get a TMDB API Key](#step-6--get-a-tmdb-api-key)
- [Step 7 — Install Prometheus & Node Exporter](#step-7--install-prometheus--node-exporter-monitoring-server)
- [Step 8 — Install Grafana](#step-8--install-grafana)
- [Step 9 — Configure Jenkins](#step-9--configure-jenkins)
- [Step 10 — Create the Jenkins Pipeline](#step-10--create-the-jenkins-pipeline)
- [Step 11 — Access the Application](#step-11--access-the-application)
- [Key Lessons from Real Implementation](#-key-lessons-from-real-implementation)
- [Special Thanks](#-special-thanks)

---

## Project Overview

This project walks through building a complete DevSecOps CI/CD pipeline for a Netflix Clone application. The stack covers everything from infrastructure provisioning and security scanning to monitoring and automated deployment.

---

## Architecture

Two separate EC2 instances are used:

**Instance 1 — DevSecOps Server**
Hosts Jenkins, Docker, SonarQube, Trivy, OWASP Dependency Check, and the Netflix Clone deployment.

**Instance 2 — Monitoring Server**
Hosts Prometheus, Grafana, and Node Exporter. Kept separate to isolate the monitoring workload from the Jenkins server.

---

## Tools & Technologies

| Tool | Purpose |
|---|---|
| AWS EC2 | Cloud infrastructure |
| Jenkins | CI/CD automation |
| Docker | Containerization |
| SonarQube | Code quality analysis |
| Trivy | Filesystem & image vulnerability scanning |
| OWASP Dependency Check | Known CVE detection |
| Prometheus | Metrics collection |
| Grafana | Monitoring dashboards |
| DockerHub | Container image registry |
| TMDB API | Movie database for the Netflix Clone |

---

## 🔌 Port Reference

| Service | Port |
|---|---|
| Jenkins | 8080 |
| SonarQube | 9000 |
| Prometheus | 9090 |
| Grafana | 3000 |
| Node Exporter | 9100 |
| Netflix App | 8081 |

---

## Step 1 — Launch EC2 Instances

Launch two EC2 instances with the following configuration:

- **OS:** Ubuntu 24.04
- **Instance type:** m7i-flex.large
- **Key pair:** RSA (.pem format)

Connect to the DevSecOps server via SSH:

```bash
ssh -i key.pem ubuntu@<public-ip>
```

Open all ports listed in the Port Reference table above as inbound rules in your Security Group.

---

## Step 2 — Install Jenkins

```bash
vi jenkins.sh
```

```bash
#!/bin/bash
sudo apt update -y
sudo apt install -y openjdk-17-jdk wget curl gnupg net-tools

wget https://get.jenkins.io/debian-stable/jenkins_2.504.1_all.deb
sudo dpkg -i jenkins_2.504.1_all.deb
sudo apt --fix-broken install -y

sudo systemctl enable jenkins
sudo systemctl restart jenkins
sudo systemctl status jenkins
```

```bash
sudo chmod +x jenkins.sh && ./jenkins.sh
```

Access Jenkins at `http://<public-ip>:8080` and retrieve the initial admin password:

```bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

Install suggested plugins and create your admin account.

---

## Step 3 — Install Docker

```bash
vi docker.sh
```

```bash
#!/bin/bash
sudo apt-get update
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker $USER
```

```bash
sudo chmod +x docker.sh && ./docker.sh
```

Fix Docker group permissions for the current session:

```bash
newgrp docker
docker run hello-world
```

---

## Step 4 — Deploy SonarQube

```bash
docker run -d --name sonar -p 9000:9000 sonarqube:lts-community
```

Access at `http://<public-ip>:9000`. Default credentials: `admin / admin`

> **Troubleshooting:** If the container keeps stopping, it is likely due to low disk space or Elasticsearch memory pressure. Check logs with `docker ps -a` and `docker logs sonar`. If disk usage is near 100%, expand the EBS volume from the AWS Console, then verify with `df -h`.

---

## Step 5 — Install Trivy

```bash
vi trivy.sh
```

```bash
#!/bin/bash
sudo apt-get install -y wget apt-transport-https gnupg lsb-release
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/trivy.list
sudo apt-get update
sudo apt-get install -y trivy
```

```bash
sudo chmod +x trivy.sh && ./trivy.sh
trivy --version
```

---

## Step 6 — Get a TMDB API Key

1. Create an account at [themoviedb.org](https://www.themoviedb.org)
2. Go to **Settings → API → Create → Developer**
3. Accept terms and fill in basic details
4. Copy the generated API key — this will be injected into the Docker build as a secret

---

## Step 7 — Install Prometheus & Node Exporter (Monitoring Server)

SSH into the second EC2 instance for all monitoring setup.

### Create a dedicated Prometheus user

```bash
sudo useradd --system --no-create-home --shell /bin/false prometheus
```

### Install Prometheus

```bash
wget https://github.com/prometheus/prometheus/releases/download/v2.47.1/prometheus-2.47.1.linux-amd64.tar.gz
tar -xvf prometheus-2.47.1.linux-amd64.tar.gz

sudo mkdir -p /data /etc/prometheus
cd prometheus-2.47.1.linux-amd64/

sudo mv prometheus promtool /usr/local/bin/
sudo mv consoles/ console_libraries/ /etc/prometheus/
sudo mv prometheus.yml /etc/prometheus/prometheus.yml

sudo chown -R prometheus:prometheus /etc/prometheus/ /data/
cd .. && rm -rf prometheus-2.47.1.linux-amd64.tar.gz
```

### Create the Prometheus systemd service

```bash
sudo vim /etc/systemd/system/prometheus.service
```

```ini
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target
StartLimitIntervalSec=500
StartLimitBurst=5

[Service]
User=prometheus
Group=prometheus
Type=simple
Restart=on-failure
RestartSec=5s
ExecStart=/usr/local/bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/data \
  --web.console.templates=/etc/prometheus/consoles \
  --web.console.libraries=/etc/prometheus/console_libraries \
  --web.listen-address=0.0.0.0:9090 \
  --web.enable-lifecycle

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl enable prometheus
sudo systemctl start prometheus
sudo systemctl status prometheus
```

### Install Node Exporter

```bash
sudo useradd --system --no-create-home --shell /bin/false node_exporter

wget https://github.com/prometheus/node_exporter/releases/download/v1.6.1/node_exporter-1.6.1.linux-amd64.tar.gz
tar -xvf node_exporter-1.6.1.linux-amd64.tar.gz
sudo mv node_exporter-1.6.1.linux-amd64/node_exporter /usr/local/bin/
rm -rf node_exporter*
```

```bash
sudo vim /etc/systemd/system/node_exporter.service
```

```ini
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target
StartLimitIntervalSec=500
StartLimitBurst=5

[Service]
User=node_exporter
Group=node_exporter
Type=simple
Restart=on-failure
RestartSec=5s
ExecStart=/usr/local/bin/node_exporter --collector.logind

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl enable node_exporter
sudo systemctl start node_exporter
sudo systemctl status node_exporter
```

### Configure Prometheus scrape targets

```bash
sudo vim /etc/prometheus/prometheus.yml
```

Add under `scrape_configs`:

```yaml
  - job_name: 'node_exporter'
    static_configs:
      - targets: ['localhost:9100']

  - job_name: 'jenkins'
    metrics_path: '/prometheus'
    static_configs:
      - targets: ['<jenkins-ip>:8080']
```

Validate and reload without downtime:

```bash
promtool check config /etc/prometheus/prometheus.yml
curl -X POST http://localhost:9090/-/reload
```

---

## Step 8 — Install Grafana

```bash
sudo apt-get install -y apt-transport-https software-properties-common
wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
echo "deb https://packages.grafana.com/oss/deb stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list
sudo apt-get update
sudo apt-get install -y grafana

sudo systemctl enable grafana-server
sudo systemctl start grafana-server
```

Access Grafana at `http://<monitoring-ip>:3000` with credentials `admin / admin`.

Add Prometheus as a data source (`http://localhost:9090`) then import these dashboards:

| Dashboard | ID |
|---|---|
| Node Exporter | 1860 |
| Jenkins | 9964 |

---

## Step 9 — Configure Jenkins

### Install required plugins

Go to **Manage Jenkins → Plugins → Available Plugins** and install:

- Eclipse Temurin Installer
- SonarQube Scanner
- NodeJS Plugin
- OWASP Dependency Check
- Docker, Docker Commons, Docker Pipeline, Docker API, docker-build-step
- Prometheus metrics
- Email Extension Plugin

### Configure tools

Go to **Manage Jenkins → Tools** and configure:

| Tool | Name |
|---|---|
| JDK | jdk17 |
| NodeJS | node16 |
| SonarQube Scanner | sonar-scanner |
| Dependency-Check | DP-Check |
| Docker | docker |

### Add credentials

Go to **Manage Jenkins → Credentials** and add:

| Credential | Type | ID |
|---|---|---|
| SonarQube token | Secret Text | Sonar-token |
| DockerHub | Username/Password | docker |
| TMDB API key | Secret Text | tmdb-api-key |
| Gmail app password | Username/Password | mail |

### Configure SonarQube server

Go to **Manage Jenkins → System → SonarQube servers** and add your server URL with the token credential.

In SonarQube go to **Administration → Configuration → Webhooks** and create a webhook:

```
http://<jenkins-ip>:8080/sonarqube-webhook/
```

> This resolves the Quality Gate infinite waiting issue.

### Configure email notifications

Go to **Manage Jenkins → System → Extended E-mail Notification**:

- SMTP server: `smtp.gmail.com`
- Port: `465`
- Enable SSL
- Credentials: your Gmail app password credential

---

## Step 10 — Create the Jenkins Pipeline

Create a new Pipeline job named `Netflix` and use the following declarative pipeline:

```groovy
pipeline {
    agent any
    tools {
        jdk 'jdk17'
        nodejs 'node16'
    }
    environment {
        SCANNER_HOME = tool 'sonar-scanner'
    }
    stages {

        stage('Workspace Cleanup') {
            steps {
                cleanWs()
            }
        }

        stage('Git Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/Aj7Ay/Netflix-clone.git'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('sonar-server') {
                    sh '''$SCANNER_HOME/bin/sonar-scanner \
                        -Dsonar.projectName=Netflix \
                        -Dsonar.projectKey=Netflix'''
                }
            }
        }

        stage('Quality Gate') {
            steps {
                script {
                    waitForQualityGate abortPipeline: false, credentialsId: 'Sonar-token'
                }
            }
        }

        stage('Install Dependencies') {
            steps {
                sh 'npm install'
            }
        }

        stage('OWASP Dependency Check') {
            steps {
                dependencyCheck additionalArguments: '--scan ./ --disableYarnAudit --disableNodeAudit --noupdate', odcInstallation: 'DP-Check'
                dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
            }
        }

        stage('Trivy Filesystem Scan') {
            steps {
                sh 'trivy fs . > trivyfs.txt'
            }
        }

        stage('Docker Build & Push') {
            steps {
                script {
                    withCredentials([string(credentialsId: 'tmdb-api-key', variable: 'TMDB_KEY')]) {
                        withDockerRegistry(credentialsId: 'docker', toolName: 'docker') {
                            sh 'docker build --build-arg TMDB_V3_API_KEY=$TMDB_KEY -t netflix .'
                            sh 'docker tag netflix josescript7/netflix:latest'
                            sh 'docker push josescript7/netflix:latest'
                        }
                    }
                }
            }
        }

        stage('Trivy Image Scan') {
            steps {
                sh 'trivy image josescript7/netflix:latest > trivyimage.txt'
            }
        }

        stage('Deploy to Container') {
            steps {
                sh 'docker stop netflix || true'
                sh 'docker rm netflix || true'
                sh 'docker run -d --name netflix -p 8081:80 josescript7/netflix:latest'
            }
        }
    }

    post {
        always {
            emailext(
                attachLog: true,
                subject: "'${currentBuild.result}'",
                body: """
                    Project: ${env.JOB_NAME}<br/>
                    Build Number: ${env.BUILD_NUMBER}<br/>
                    URL: ${env.BUILD_URL}<br/>
                """,
                to: 'your-email@gmail.com',
                attachmentsPattern: 'trivyfs.txt,trivyimage.txt'
            )
        }
    }
}
```

> **Note on OWASP:** If you encounter NVD database corruption or `ClosedChannelException` errors, add `--noupdate` to the OWASP arguments as shown above and delete the corrupted database files from the Jenkins workspace.

---

## Step 11 — Access the Application

Once the pipeline runs successfully, the Netflix Clone is accessible at:

```
http://<jenkins-server-ip>:8081
```

The Docker image is automatically built, scanned, pushed to DockerHub, and deployed on every pipeline run.

---

## Key Lessons from Real Implementation

- **EBS storage fills up fast.** SonarQube, Docker images, and the OWASP NVD database together consumed nearly all disk. Plan for at least 30GB on the DevSecOps server.
- **OWASP database corruption is common.** Using `--noupdate` in the pipeline after an initial clean download is a reliable workaround.
- **SonarQube Quality Gate hangs** if the webhook is not configured correctly. The webhook URL must point to `/sonarqube-webhook/` on Jenkins.
- **Docker group permissions** require `newgrp docker` or a session restart after adding a user to the group.
- **Never hardcode the TMDB API key.** Use Jenkins Secret Text credentials and inject it as a build argument at runtime.

---

## Special Thanks

A big thank you to **[@NotHarshhaa](https://github.com/NotHarshhaa)** and the **ProDevOpsGuy Tech Community** for the original content and inspiration behind this project. Visit [harshhaareddy.site](https://harshhaareddy.site) to explore more of their work.

> *"Start copying what you love. Copy copy copy copy. At the end of the copy you will find yourself."*
> *"The human hand is incapable of making a perfect copy."*
> — Austin Kleon, Steal Like an Artist

This is the whole point. Even when you try to replicate something exactly, your own experiences, decisions, and instincts quietly reshape it into something uniquely yours. Influence is not theft. It is the starting point of every creative journey.

So go ahead. Follow this guide. Replicate it step by step. Break things, fix them, wonder why something works the way it does. By the time you finish, you won't have just copied a project. You'll have built your own understanding, your own muscle memory, and somewhere in there, your own version.

**Start building. You'll find yourself at the end of it.**

---

<div align="center">

⭐ If you found this helpful, consider starring the repo!

</div>
