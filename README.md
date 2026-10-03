# EazyBank Microservices

An enterprise-grade, event-driven banking application built with **Spring Boot**, **Spring Cloud**, **Apache Kafka**, **Keycloak**, and **Kubernetes**.

---

## 🏛 Architecture Overview

The system follows a microservices architecture where internal services are securely isolated within the Kubernetes cluster as `ClusterIP`, and external traffic is routed through the **API Gateway** (`gatewayserver`) and authenticated via **Keycloak**.

```
                           [ Clients / Browsers ]
                                     |
             +-----------------------+-----------------------+
             |                                               |
             v (HTTP 8072)                                   v (HTTP 7080)
   +-------------------+                           +-------------------+
   |   gatewayserver   |                           |     keycloak      |
   |   (LoadBalancer)  |                           |   (LoadBalancer)  |
   +---------+---------+                           +-------------------+
             |
   +---------+--------------------+---------------------+
   | (ClusterIP)                  | (ClusterIP)         | (ClusterIP)
   v                              v                     v
+--------------+           +--------------+      +--------------+
|   accounts   |           |    loans     |      |    cards     |
|  (Port 8080) |           |  (Port 8090) |      |  (Port 9000) |
+-------+------+           +--------------+      +--------------+
        | OpenFeign
        +-----------------------------------------------+
        |
        v (send-communication)
+-------------------------------------------------------+
|                    Apache Kafka                       |
|               (ClusterIP - Port 9092)                 |
+-------------------------------------------------------+
        |
        v (communication-sent)
+--------------+
|   message    |
|  (Port 9010) |
+--------------+
```

---

## 📦 Microservices & Components

| Component | Port | Service Type | Description |
| :--- | :---: | :---: | :--- |
| **`gatewayserver`** | `8072` | `LoadBalancer` | API Gateway with Spring Cloud Gateway, Redis Rate Limiter, Resilience4j Circuit Breaker, and OAuth2 JWT authentication. |
| **`accounts`** | `8080` | `ClusterIP` | Core bank account services, OpenFeign client for Cards/Loans, and Kafka message producer. |
| **`loans`** | `8090` | `ClusterIP` | Loan management service with H2 in-memory persistence and JPA. |
| **`cards`** | `9000` | `ClusterIP` | Credit/Debit card management service. |
| **`message`** | `9010` | `ClusterIP` | Notification service with Spring Cloud Stream (Kafka binder) handling email & SMS notifications. |
| **`configserver`** | `8071` | `ClusterIP` | Centralized configuration server backed by Git repository. |
| **`spring-cloud-kubernetes-discoveryserver`** | `80` / `8761` | `ClusterIP` | Kubernetes-native service discovery registry. |
| **`kafka`** | `9092` | `ClusterIP` | Event broker running in Apache Kafka KRaft mode. |
| **`keycloak`** | `7080` | `LoadBalancer` | Identity & Access Management (OAuth2 / OIDC). |

---

## 🛠 Tech Stack

- **Java**: 25
- **Spring Boot**: 4.1.1
- **Spring Cloud**: 2025.1.3
  - Spring Cloud Gateway (WebFlux)
  - Spring Cloud Config Server
  - Spring Cloud Kubernetes Discovery Client & Server
  - Spring Cloud OpenFeign
  - Spring Cloud Stream (Kafka Binder)
- **Security**: Spring Security OAuth2 Resource Server, Keycloak 26
- **Messaging**: Apache Kafka 4.3 (KRaft mode)
- **Resilience**: Resilience4j (Circuit Breaker, Retry, Rate Limiter)
- **Containerization & Orchestration**: Docker, Jib, Kubernetes (Kind / Docker Desktop)

---

## 🚀 Getting Started

### Prerequisites

- **Java JDK 25**
- **Maven 3.9+**
- **Docker Desktop** (with Kubernetes enabled) or a local **Kind** cluster
- **kubectl** CLI

---

### 1. Build Container Images

Use the automated build script to compile and generate Docker images for all services using Jib:

#### Windows:
```cmd
build-scripts\build-images.cmd
```

#### Parallel build:
```cmd
build-scripts\build-images.cmd --parallel
```

*(Builds images tagged as `:s17` directly into your local Docker daemon).*

---

### 2. Deploy to Kubernetes

Deploy scripts are provided in both Windows Batch (`.cmd`) and Linux/macOS Bash (`.sh`):

#### On Windows (Command Prompt):
```cmd
deploy.cmd apply
```

#### On Linux / macOS / Git Bash:
```bash
chmod +x deploy.sh kubernates/deploy.sh
./deploy.sh apply
```

#### What happens during deployment:
1. **ConfigMap**: Loads environment variables (`SPRING_CONFIG_IMPORT`, `SPRING_CLOUD_KUBERNETES_DISCOVERY_DISCOVERY_SERVER_URL`, Kafka brokers, etc.).
2. **Discovery Server**: Starts Spring Cloud Kubernetes Discovery Server and sets up RBAC permissions.
3. **Core Infra**: Starts Keycloak, Config Server, and Apache Kafka.
4. **Internal Microservices**: Starts `accounts`, `loans`, `cards` as private `ClusterIP` services.
5. **Gateway & Message**: Starts `gatewayserver` as `LoadBalancer` and `message` event consumer.

---

### 3. Check Deployment Status

#### Windows:
```cmd
deploy.cmd status
```

#### Linux / macOS:
```bash
./deploy.sh status
```

Or directly using `kubectl`:
```powershell
kubectl get pods
kubectl get svc
```

---

### 4. Teardown / Delete Resources

To clean up all deployed pods and services cleanly:

#### Windows:
```cmd
deploy.cmd delete
```

#### Linux / macOS:
```bash
./deploy.sh delete
```

---

## 📊 Viewing Logs

View logs by microservice label without needing the specific pod name:

```powershell
# Accounts service logs
kubectl logs -l app=accounts -f

# Message notification logs
kubectl logs -l app=message -f

# Gateway server logs
kubectl logs -l app=gatewayserver -f

# Config Server logs
kubectl logs -l app=configserver -f
```

---

## 🌐 API Routing via Gateway

All client requests should pass through the API Gateway at port `8072`:

| Path Pattern | Target Microservice |
| :--- | :--- |
| `http://localhost:8072/eazybank/accounts/**` | `accounts:8080` |
| `http://localhost:8072/eazybank/cards/**` | `cards:9000` |
| `http://localhost:8072/eazybank/loans/**` | `loans:8090` |
