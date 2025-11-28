# Skill Tracker - Architecture Diagrams

Visual representations of the Skill Tracker architecture using both professional generated diagrams and Mermaid (inline) diagrams.

## Professional Diagrams (Generated with AWS Icons)

We have generated professional architecture diagrams with official AWS icons using Python's `diagrams` library.

### Generated Diagram Files

| Diagram | File | Description |
|---------|------|-------------|
| **Architecture Overview** | [architecture_overview.png](../diagrams/architecture_overview.png) | Complete system with all 12 microservices |
| **Network Architecture** | [network_architecture.png](../diagrams/network_architecture.png) | VPC topology and network flow |
| **CI/CD Pipeline** | [cicd_pipeline.png](../diagrams/cicd_pipeline.png) | Complete deployment workflow |
| **Monitoring Stack** | [monitoring_stack.png](../diagrams/monitoring_stack.png) | Observability architecture |
| **Data Flow** | [data_flow.png](../diagrams/data_flow.png) | Task submission data flow |

### Viewing the Diagrams

**In GitHub**: Click the links above to view the diagrams

**Locally**: Open the PNG files in `diagrams/` folder

**Regenerate**: See [diagrams/README.md](../diagrams/README.md) for instructions

---

## Interactive Diagrams (Mermaid)

> **Note**: Mermaid diagrams render directly in GitHub, GitLab, and most modern markdown viewers.

## System Overview

```mermaid
graph TB
    subgraph Internet
        Users[👥 Users]
    end
    
    subgraph "AWS Cloud"
        subgraph "Frontend Layer"
            CF[☁CloudFront CDN]
            Amplify[📱 AWS Amplify<br/>Angular App]
        end
        
        subgraph "API Layer"
            ALB[Application Load Balancer]
            APIGW[API Gateway :8080]
        end
        
        subgraph "ECS Fargate Cluster"
            Config[Config Server :8081]
            Discovery[Discovery Server :8082]
            UserSvc[User Service :8083]
            TaskSvc[Task Service :8084]
            SkillSvc[Skill Service :8085]
            AnalyticsSvc[Analytics Service :8087]
            NotifSvc[🔔 Notification Service :8089]
        end
        
        subgraph "Data Services"
            Mongo[(MongoDB)]
            RabbitMQ[RabbitMQ]
            Redis[(⚡ Redis)]
        end
        
        subgraph "Database Layer"
            RDS[(PostgreSQL RDS<br/>Multi-AZ)]
        end
        
        subgraph "Storage"
            S3[🪣 S3 Buckets]
        end
        
        subgraph "Monitoring"
            Grafana[Grafana]
            CloudWatch[☁CloudWatch]
        end
    end
    
    Users --> CF
    CF --> Amplify
    CF --> ALB
    ALB --> APIGW
    APIGW --> Config
    APIGW --> Discovery
    APIGW --> UserSvc
    APIGW --> TaskSvc
    APIGW --> SkillSvc
    APIGW --> AnalyticsSvc
    APIGW --> NotifSvc
    
    UserSvc --> RDS
    TaskSvc --> RDS
    TaskSvc --> Mongo
    SkillSvc --> RDS
    AnalyticsSvc --> Mongo
    NotifSvc --> Mongo
    NotifSvc --> RabbitMQ
    
    UserSvc --> Redis
    APIGW --> Redis
    
    UserSvc --> S3
    TaskSvc --> S3
    
    CloudWatch -.-> Grafana
    
    style CF fill:#FF9900,stroke:#232F3E,stroke-width:2px,color:#fff
    style Amplify fill:#FF9900,stroke:#232F3E,stroke-width:2px,color:#fff
    style ALB fill:#FF9900,stroke:#232F3E,stroke-width:2px,color:#fff
    style RDS fill:#3B48CC,stroke:#232F3E,stroke-width:2px,color:#fff
    style Mongo fill:#47A248,stroke:#232F3E,stroke-width:2px,color:#fff
    style Redis fill:#DC382D,stroke:#232F3E,stroke-width:2px,color:#fff
```

## Request Flow - Frontend to Backend

```mermaid
sequenceDiagram
    participant User as User Browser
    participant CF as ☁CloudFront
    participant Amplify as 📱 Amplify
    participant ALB as ALB
    participant APIGW as API Gateway
    participant UserSvc as User Service
    participant RDS as PostgreSQL
    
    User->>CF: Request static assets
    CF->>Amplify: Forward request
    Amplify-->>CF: Return HTML/JS/CSS
    CF-->>User: Cached response
    
    Note over User,CF: API Call Flow
    
    User->>CF: POST /api/users/login
    CF->>ALB: Forward API request
    ALB->>APIGW: Route to API Gateway
    APIGW->>APIGW: Validate JWT
    APIGW->>UserSvc: Forward to User Service
    UserSvc->>RDS: Query user data
    RDS-->>UserSvc: Return user
    UserSvc-->>APIGW: Return response
    APIGW-->>ALB: Return response
    ALB-->>CF: Return response
    CF-->>User: Return JSON
```

## OAuth Authentication Flow

```mermaid
sequenceDiagram
    participant User as User
    participant Frontend as 📱 Frontend
    participant Google as Google OAuth
    participant APIGW as API Gateway
    participant UserSvc as User Service
    participant RDS as PostgreSQL
    
    User->>Frontend: Click "Login with Google"
    Frontend->>Google: Redirect to OAuth consent
    Google->>User: Show consent screen
    User->>Google: Authorize app
    Google->>Frontend: Redirect with code
    Frontend->>APIGW: POST /api/auth/google {code}
    APIGW->>UserSvc: Forward request
    UserSvc->>Google: Exchange code for token
    Google-->>UserSvc: Return access token
    UserSvc->>Google: Fetch user profile
    Google-->>UserSvc: Return profile
    UserSvc->>RDS: Create/update user
    RDS-->>UserSvc: User saved
    UserSvc->>UserSvc: Generate JWT
    UserSvc-->>APIGW: Return JWT
    APIGW-->>Frontend: Return JWT
    Frontend->>Frontend: Store JWT in cookie
    Frontend-->>User: Redirect to dashboard
```

## Service Discovery Flow

```mermaid
graph LR
    subgraph "Service Startup"
        Start[Service Starts] --> ReadConfig[Read Config<br/>from Config Server]
        ReadConfig --> Register[Register with<br/>Discovery Server]
        Register --> Discover[Discover Other<br/>Services]
        Discover --> Heartbeat[💓 Send Heartbeats<br/>every 30s]
    end
    
    subgraph "Config Server :8081"
        ConfigSvc[Config Server]
    end
    
    subgraph "Discovery Server :8082"
        DiscoverySvc[Eureka Server]
    end
    
    ReadConfig --> ConfigSvc
    Register --> DiscoverySvc
    Discover --> DiscoverySvc
    Heartbeat --> DiscoverySvc
    
    style Start fill:#4CAF50,stroke:#2E7D32,stroke-width:2px,color:#fff
    style ConfigSvc fill:#FF9800,stroke:#E65100,stroke-width:2px,color:#fff
    style DiscoverySvc fill:#2196F3,stroke:#0D47A1,stroke-width:2px,color:#fff
```

## CI/CD Pipeline Flow

```mermaid
graph TB
    subgraph "Developer"
        Dev[👨‍💻 Developer] --> Push[📤 Push to GitHub]
    end
    
    subgraph "GitHub Actions"
        Push --> Detect[Detect Changed<br/>Services]
        Detect --> Build[🔨 Build Shared<br/>Dependencies]
        Build --> BuildSvc[🔨 Build Services]
        BuildSvc --> Test[Run Tests]
        Test --> Sonar[SonarQube<br/>Analysis]
        Sonar --> Quality{Quality<br/>Gate Pass?}
        Quality -->|Yes| Docker[Build Docker<br/>Images]
        Quality -->|No| Fail[Fail Build]
        Docker --> ECR[Push to ECR<br/>:latest & :sha]
        ECR --> Dispatch[📨 Repository<br/>Dispatch]
    end
    
    subgraph "DevOps Repo"
        Dispatch --> UpdateTask[Update ECS<br/>Task Definitions]
        UpdateTask --> Deploy[Deploy to ECS]
        Deploy --> Health[🏥 Health Check]
        Health --> Success{Healthy?}
        Success -->|Yes| Notify[📢 Slack Success]
        Success -->|No| Rollback[⏪ Rollback]
    end
    
    style Quality fill:#FFC107,stroke:#F57F17,stroke-width:2px,color:#000
    style Success fill:#FFC107,stroke:#F57F17,stroke-width:2px,color:#000
    style Notify fill:#4CAF50,stroke:#2E7D32,stroke-width:2px,color:#fff
    style Fail fill:#F44336,stroke:#C62828,stroke-width:2px,color:#fff
    style Rollback fill:#F44336,stroke:#C62828,stroke-width:2px,color:#fff
```

## Data Flow - Task Submission

```mermaid
sequenceDiagram
    participant User as User
    participant APIGW as API Gateway
    participant TaskSvc as Task Service
    participant PG as PostgreSQL
    participant Mongo as MongoDB
    participant RabbitMQ as RabbitMQ
    participant Analytics as Analytics
    participant Notif as 🔔 Notification
    
    User->>APIGW: Submit task
    APIGW->>TaskSvc: POST /api/tasks
    
    par Save to PostgreSQL
        TaskSvc->>PG: Save task metadata
        PG-->>TaskSvc: Task ID
    and Save to MongoDB
        TaskSvc->>Mongo: Save submission details
        Mongo-->>TaskSvc: Submission ID
    end
    
    TaskSvc->>RabbitMQ: Publish TaskSubmitted event
    TaskSvc-->>APIGW: Return success
    APIGW-->>User: Task submitted
    
    par Process Events
        RabbitMQ->>Analytics: TaskSubmitted event
        Analytics->>Mongo: Record metrics
    and
        RabbitMQ->>Notif: TaskSubmitted event
        Notif->>Mongo: Create notification
        Notif->>User: Send notification
    end
```

## Monitoring & Observability Flow

```mermaid
graph TB
    subgraph "Application Services"
        Services[12 Microservices]
    end
    
    subgraph "Logs"
        Services -->|Logs| CWLogs[☁CloudWatch Logs]
        CWLogs -->|Export| Lambda[⚡ Lambda Exporter]
        Lambda -->|Archive| S3Logs[🪣 S3 Logs Bucket]
    end
    
    subgraph "Metrics"
        Services -->|Metrics| CWMetrics[CloudWatch Metrics]
        CWMetrics -->|Query| Grafana[Grafana]
    end
    
    subgraph "Traces"
        Services -->|Traces| XRay[AWS X-Ray]
    end
    
    subgraph "Alarms"
        CWMetrics -->|Threshold| Alarms[CloudWatch Alarms]
        Alarms -->|Notify| SNS[📧 SNS Topic]
        SNS -->|Email| Email[📧 Email]
        SNS -->|Webhook| Slack[💬 Slack]
    end
    
    subgraph "Cost Monitoring"
        CostAPI[Cost Explorer API] -->|Fetch| CostLambda[⚡ Cost Exporter]
        CostLambda -->|Publish| CWMetrics
    end
    
    style Grafana fill:#F46800,stroke:#000,stroke-width:2px,color:#fff
    style Alarms fill:#F44336,stroke:#C62828,stroke-width:2px,color:#fff
    style Slack fill:#4A154B,stroke:#000,stroke-width:2px,color:#fff
```

## Network Architecture

```mermaid
graph TB
    subgraph "Internet"
        Internet[Internet]
    end
    
    subgraph "VPC 10.x.0.0/16"
        subgraph "Public Subnet 1 - AZ-1a"
            ALB1[ALB]
            NAT1[NAT Gateway]
        end
        
        subgraph "Public Subnet 2 - AZ-1b"
            ALB2[ALB]
            NAT2[NAT Gateway]
        end
        
        subgraph "Private Subnet 1 - AZ-1a"
            ECS1[ECS Tasks]
            RDS1[RDS Primary]
        end
        
        subgraph "Private Subnet 2 - AZ-1b"
            ECS2[ECS Tasks]
            RDS2[RDS Standby]
        end
        
        IGW[Internet Gateway]
    end
    
    Internet --> IGW
    IGW --> ALB1
    IGW --> ALB2
    ALB1 --> ECS1
    ALB2 --> ECS2
    ECS1 --> NAT1
    ECS2 --> NAT2
    NAT1 --> IGW
    NAT2 --> IGW
    ECS1 --> RDS1
    ECS2 --> RDS1
    RDS1 -.Replication.-> RDS2
    
    style IGW fill:#FF9900,stroke:#232F3E,stroke-width:2px,color:#fff
    style NAT1 fill:#FF9900,stroke:#232F3E,stroke-width:2px,color:#fff
    style NAT2 fill:#FF9900,stroke:#232F3E,stroke-width:2px,color:#fff
```

## Auto-Scaling Behavior

```mermaid
stateDiagram-v2
    [*] --> Normal: CPU < 70%
    Normal --> ScalingOut: CPU > 70%
    ScalingOut --> HighLoad: Add tasks
    HighLoad --> ScalingOut: Still CPU > 70%
    HighLoad --> Normal: CPU < 70%
    Normal --> ScalingIn: CPU < 50% for 5min
    ScalingIn --> Normal: Remove tasks
    
    note right of Normal
        Min tasks: 2
        CPU: 40-60%
        Status: Stable
    end note
    
    note right of HighLoad
        Max tasks: 8
        CPU: 50-70%
        Status: Scaled
    end note
```

## Deployment Environments

```mermaid
graph LR
    subgraph "Development"
        Dev[Dev Environment<br/>10.0.0.0/16<br/>1-2 tasks<br/>db.t3.micro]
    end
    
    subgraph "Staging"
        Stage[Staging Environment<br/>10.1.0.0/16<br/>1-4 tasks<br/>db.t3.small]
    end
    
    subgraph "Production"
        Prod[Production Environment<br/>10.2.0.0/16<br/>2-8 tasks<br/>db.r5.large Multi-AZ]
    end
    
    Dev -->|Promote| Stage
    Stage -->|Promote| Prod
    
    style Dev fill:#4CAF50,stroke:#2E7D32,stroke-width:2px,color:#fff
    style Stage fill:#FF9800,stroke:#E65100,stroke-width:2px,color:#fff
    style Prod fill:#F44336,stroke:#C62828,stroke-width:2px,color:#fff
```

## Service Dependencies

```mermaid
graph TD
    Config[Config Server :8081<br/>Must start FIRST]
    Discovery[Discovery Server :8082<br/>Must start SECOND]
    APIGW[API Gateway :8080<br/>Must start THIRD]
    
    subgraph "Data Services - Start in Parallel"
        Mongo[MongoDB]
        RabbitMQ[RabbitMQ]
        Redis[⚡ Redis]
        RDS[PostgreSQL RDS]
    end
    
    subgraph "Application Services - Start in Parallel"
        UserSvc[User Service]
        TaskSvc[Task Service]
        SkillSvc[Skill Service]
        AnalyticsSvc[Analytics Service]
        NotifSvc[🔔 Notification Service]
    end
    
    Config --> Discovery
    Discovery --> APIGW
    APIGW --> UserSvc
    APIGW --> TaskSvc
    APIGW --> SkillSvc
    APIGW --> AnalyticsSvc
    APIGW --> NotifSvc
    
    RDS --> UserSvc
    RDS --> TaskSvc
    RDS --> SkillSvc
    
    Mongo --> TaskSvc
    Mongo --> AnalyticsSvc
    Mongo --> NotifSvc
    
    RabbitMQ --> NotifSvc
    Redis --> UserSvc
    Redis --> APIGW
    
    style Config fill:#E91E63,stroke:#880E4F,stroke-width:3px,color:#fff
    style Discovery fill:#9C27B0,stroke:#4A148C,stroke-width:3px,color:#fff
    style APIGW fill:#673AB7,stroke:#311B92,stroke-width:3px,color:#fff
```

---

## Generated Diagrams

For high-resolution AWS architecture diagrams with official AWS icons, see the Python-generated diagrams in the `diagrams/` folder:

- `architecture_overview.png` - Complete system architecture
- `network_architecture.png` - VPC and networking details
- `cicd_pipeline.png` - CI/CD workflow
- `data_flow.png` - Data flow patterns
- `monitoring_stack.png` - Observability architecture

To regenerate diagrams, run:

```bash
cd diagrams
python generate_all_diagrams.py
```

## Diagram Tools Used

### Mermaid (Inline Diagrams)
- **Pros**: Renders in GitHub, version controlled, easy to update
- **Cons**: Limited styling, no official AWS icons
- **Best for**: Flows, sequences, state diagrams

### Python Diagrams (Generated Images)
- **Pros**: Professional AWS icons, high quality, automated
- **Cons**: Requires Python, generates binary files
- **Best for**: Architecture diagrams, presentations

### ASCII Diagrams (Fallback)
- **Pros**: Works everywhere, no dependencies
- **Cons**: Limited visual appeal
- **Best for**: Quick reference, documentation

## Viewing Mermaid Diagrams

Mermaid diagrams render automatically in:
- GitHub
- GitLab
- VS Code (with Markdown Preview Mermaid Support extension)
- IntelliJ IDEA (with Mermaid plugin)
- Obsidian
- Notion

If diagrams don't render, view them at: https://mermaid.live/

---

**Last Updated**: November 28, 2025
**Maintained By**: DevOps Team
