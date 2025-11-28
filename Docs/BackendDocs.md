# Backend Documentation - Skill Tracker

## Overview

The Skill Tracker backend consists of 8 microservices built with Spring Boot, deployed on AWS ECS Fargate. The architecture follows microservices patterns with service discovery, centralized configuration, and polyglot persistence.

## Microservices Architecture

### Service Inventory

**Active Services (Deployed & Working):**

| Service | Port | Database | Purpose |
|---------|------|----------|---------|
| **Core Services** | | | |
| Config Server | 8081 | - | Centralized configuration management |
| Discovery Server (Eureka) | 8082 | - | Service registry and discovery |
| API Gateway | 8080 | - | Request routing and authentication |
| **Business Services** | | | |
| User Service | 8083 | PostgreSQL + Redis | User management and authentication |
| Task Service | 8084 | PostgreSQL + MongoDB | Task management and submissions |
| Analytics Service | 8087 | MongoDB | Usage analytics and metrics |
| Feedback Service | 8088 | PostgreSQL | User feedback collection |
| Notification Service | 8089 | MongoDB + RabbitMQ | Real-time notifications |

**Data Services (ECS Containers):**

| Service | Port | Purpose |
|---------|------|---------|
| MongoDB | 27017 | Document database for analytics, tasks, notifications |
| RabbitMQ | 5672, 15672 | Message queue for async communication |
| Redis | 6379 | Caching and session management |

**Infrastructure Ready (Code Pending):**

| Service | Port | Status |
|---------|------|--------|
| BFF Service | - | Backend development pending |
| Payment Service | - | Backend development pending |
| Gamification Service | - | Backend development pending |
| Practice Service | - | Backend development pending |

> **Note**: Infrastructure is configured for additional services. The 4 planned services have infrastructure ready but are awaiting backend development completion.

## Technology Stack

- **Framework**: Spring Boot 3.x
- **Build Tool**: Maven
- **Language**: Java 17
- **Service Discovery**: Spring Cloud Netflix Eureka
- **Configuration**: Spring Cloud Config
- **API Gateway**: Spring Cloud Gateway
- **Message Queue**: RabbitMQ
- **Databases**: PostgreSQL 15, MongoDB 6
- **Caching**: Redis (via EFS)
- **Authentication**: JWT + OAuth 2.0
- **API Documentation**: OpenAPI/Swagger

## Architecture Patterns

### Service Discovery

All services register with Eureka Discovery Server on startup:

```yaml
eureka:
  client:
    serviceUrl:
      defaultZone: http://discovery-server:8082/eureka/
  instance:
    preferIpAddress: true
    instanceId: ${spring.application.name}:${random.value}
```

**Service Communication**:
```java
// Using service name (not hardcoded IPs)
@FeignClient(name = "user-service")
public interface UserServiceClient {
    @GetMapping("/api/users/{id}")
    User getUserById(@PathVariable Long id);
}
```

### Centralized Configuration

Spring Cloud Config Server provides configuration to all services:

```yaml
spring:
  cloud:
    config:
      uri: http://config-server:8081
      fail-fast: true
      retry:
        max-attempts: 5
```

**Configuration Repository Structure**:
```
config-repo/
├── application.yml              # Common config
├── user-service.yml             # User service config
├── task-service.yml             # Task service config
├── user-service-dev.yml         # Dev overrides
├── user-service-prod.yml        # Prod overrides
└── ...
```

### API Gateway Pattern

Spring Cloud Gateway routes requests to microservices:

```yaml
spring:
  cloud:
    gateway:
      routes:
        - id: user-service
          uri: lb://user-service
          predicates:
            - Path=/api/users/**
          filters:
            - StripPrefix=1
            - AuthenticationFilter
```

**Request Flow**:
```
Client → CloudFront → ALB → API Gateway (8080) → Microservice
```

## Shared Dependencies

### Common Modules

Located in `skilltracker-common/` directory:

1. **common-event**: Event-driven communication models
2. **common-security**: JWT authentication and authorization
3. **common-util**: Shared utilities and helpers

**Build Order** (Critical):
```bash
# Must build in this order to resolve dependencies
mvn clean install -pl skilltracker-common/common-event
mvn clean install -pl skilltracker-common/common-security
mvn clean install -pl skilltracker-common/common-util
mvn clean install -pl user-service
mvn clean install -pl task-service  # Depends on user-service
```

### Maven Configuration

```xml
<dependency>
    <groupId>com.amalitech.skilltracker</groupId>
    <artifactId>common-security</artifactId>
    <version>1.0.0</version>
</dependency>
```

## Database Architecture

### PostgreSQL Services

**Connection Configuration**:
```yaml
spring:
  datasource:
    url: jdbc:postgresql://${RDS_ENDPOINT}:5432/${DB_NAME}
    username: ${DB_USERNAME}
    password: ${DB_PASSWORD}
  jpa:
    hibernate:
      ddl-auto: validate
    properties:
      hibernate:
        dialect: org.hibernate.dialect.PostgreSQLDialect
```

**Services Using PostgreSQL**:
- user-service, task-service, skill-service
- assessment-service, feedback-service, report-service
- recommendation-service, search-service
- integration-service, collaboration-service

### MongoDB Services

**Connection Configuration**:
```yaml
spring:
  data:
    mongodb:
      uri: mongodb://${MONGODB_HOST}:27017/${MONGODB_DATABASE}
      # Legacy naming support (Sprint 3)
      host: ${MONGODB_HOST}
      port: 27017
      database: ${MONGODB_DATABASE}
```

**Services Using MongoDB**:
- analytics-service (primary)
- notification-service (primary)
- task-service (secondary - for submissions)

**Sprint 3 Note**: Added support for legacy MongoDB naming conventions to maintain backward compatibility.

### Polyglot Persistence Rationale

- **PostgreSQL**: ACID transactions, relational data, complex queries
- **MongoDB**: Flexible schemas, high write throughput, document storage

## Data Services

### MongoDB Deployment

**ECS Configuration** (Sprint 3):
```hcl
container_definitions = jsonencode([{
  name  = "mongodb"
  image = "${aws_ecr_repository.mongodb.repository_url}:latest"
  portMappings = [{
    containerPort = 27017
    protocol      = "tcp"
  }]
  environment = [
    { name = "MONGO_INITDB_ROOT_USERNAME", value = "admin" },
    { name = "MONGO_INITDB_ROOT_PASSWORD", valueFrom = "${aws_secretsmanager_secret.mongodb_password.arn}" }
  ]
}])
```

**Status**: Currently stateless (no EFS). Sprint 4 will add persistent storage.

### RabbitMQ Deployment

**ECS Configuration** (Sprint 3):
```hcl
container_definitions = jsonencode([{
  name  = "rabbitmq"
  image = "${aws_ecr_repository.rabbitmq.repository_url}:latest"
  user  = "999:999"  # RabbitMQ user (fixed permission issues)
  portMappings = [{
    containerPort = 5672
    protocol      = "tcp"
  }]
  environment = [
    { name = "RABBITMQ_ERLANG_COOKIE", valueFrom = "${aws_secretsmanager_secret.erlang_cookie.arn}" },
    { name = "TMPDIR", value = "/tmp" }
  ]
}])
```

**Sprint 3 Fixes**:
- Changed user to `999:999` to fix Erlang cookie permissions
- Added `/tmp` mount for Erlang runtime
- Stored Erlang cookie in Secrets Manager

### Redis Deployment

**Configuration**:
```yaml
spring:
  redis:
    host: ${REDIS_HOST}
    port: 6379
    password: ${REDIS_PASSWORD}
```

**Use Cases**:
- Session management (user-service)
- Caching frequently accessed data
- Rate limiting (API Gateway)

## Authentication & Authorization

### JWT Token Flow

1. User authenticates via OAuth (Google)
2. Backend generates JWT token
3. Token stored in secure cookie
4. Frontend includes token in API requests
5. API Gateway validates token
6. Request forwarded to microservice

### JWT Configuration

```java
@Configuration
public class JwtConfig {
    @Value("${jwt.secret}")
    private String secret;
    
    @Value("${jwt.expiration}")
    private Long expiration;  // 24 hours
    
    public String generateToken(UserDetails userDetails) {
        return Jwts.builder()
            .setSubject(userDetails.getUsername())
            .setIssuedAt(new Date())
            .setExpiration(new Date(System.currentTimeMillis() + expiration))
            .signWith(SignatureAlgorithm.HS512, secret)
            .compact();
    }
}
```

### OAuth 2.0 Integration

**Google OAuth Configuration**:
```yaml
spring:
  security:
    oauth2:
      client:
        registration:
          google:
            client-id: ${GOOGLE_CLIENT_ID}
            client-secret: ${GOOGLE_CLIENT_SECRET}
            redirect-uri: ${LOGIN_URL}/oauth/callback
            scope: profile, email
```

**Sprint 3 Updates**:
- Added `LOGIN_URL` environment variable
- Updated redirect URLs to CloudFront domain
- Set `COOKIE_SECURE=true` for production

## Service Communication

### Synchronous Communication (REST)

**Using Feign Client**:
```java
@FeignClient(name = "user-service")
public interface UserServiceClient {
    @GetMapping("/api/users/{id}")
    User getUserById(@PathVariable Long id);
}

// Usage
@Autowired
private UserServiceClient userServiceClient;

public void processTask(Long userId) {
    User user = userServiceClient.getUserById(userId);
    // Process task
}
```

### Asynchronous Communication (RabbitMQ)

**Publisher**:
```java
@Service
public class NotificationPublisher {
    @Autowired
    private RabbitTemplate rabbitTemplate;
    
    public void sendNotification(NotificationEvent event) {
        rabbitTemplate.convertAndSend("notification.exchange", "notification.key", event);
    }
}
```

**Consumer**:
```java
@Service
public class NotificationConsumer {
    @RabbitListener(queues = "notification.queue")
    public void handleNotification(NotificationEvent event) {
        // Process notification
    }
}
```

## API Documentation

### OpenAPI/Swagger

Each service exposes API documentation at `/swagger-ui.html`:

```java
@Configuration
public class OpenApiConfig {
    @Bean
    public OpenAPI customOpenAPI() {
        return new OpenAPI()
            .info(new Info()
                .title("User Service API")
                .version("1.0")
                .description("User management and authentication"));
    }
}
```

**Access**: `http://<alb-dns>/api/users/swagger-ui.html`

## Error Handling

### Global Exception Handler

```java
@RestControllerAdvice
public class GlobalExceptionHandler {
    
    @ExceptionHandler(ResourceNotFoundException.class)
    public ResponseEntity<ErrorResponse> handleNotFound(ResourceNotFoundException ex) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
            .body(new ErrorResponse(ex.getMessage()));
    }
    
    @ExceptionHandler(Exception.class)
    public ResponseEntity<ErrorResponse> handleGeneral(Exception ex) {
        log.error("Unexpected error", ex);
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
            .body(new ErrorResponse("Internal server error"));
    }
}
```

## Logging

### Structured Logging

```java
@Slf4j
@Service
public class UserService {
    public User createUser(UserDto dto) {
        log.info("Creating user: email={}", dto.getEmail());
        try {
            User user = userRepository.save(dto.toEntity());
            log.info("User created: id={}, email={}", user.getId(), user.getEmail());
            return user;
        } catch (Exception e) {
            log.error("Failed to create user: email={}", dto.getEmail(), e);
            throw e;
        }
    }
}
```

### CloudWatch Integration

All logs sent to CloudWatch Log Groups:
- `/ecs/sdt-dev-config-server`
- `/ecs/sdt-dev-discovery-server`
- `/ecs/sdt-dev-api-gateway`
- `/ecs/sdt-dev-user-service`
- ... (one per service)

## Health Checks

### Spring Boot Actuator

```yaml
management:
  endpoints:
    web:
      exposure:
        include: health, info, metrics
  endpoint:
    health:
      show-details: always
```

**Health Check Endpoint**: `GET /actuator/health`

**Response**:
```json
{
  "status": "UP",
  "components": {
    "db": { "status": "UP" },
    "diskSpace": { "status": "UP" },
    "ping": { "status": "UP" }
  }
}
```

**Sprint 3 Note**: Health checks removed from ECS task definitions due to `curl` unavailability in containers. ALB health checks used instead.

## Monitoring

### Metrics

Spring Boot Actuator exposes metrics:
- JVM memory usage
- CPU usage
- HTTP request count
- Database connection pool
- Custom business metrics

### CloudWatch Metrics

ECS Container Insights provides:
- CPU utilization
- Memory utilization
- Network I/O
- Task count

### Distributed Tracing

**AWS X-Ray Integration** (Staging/Production):
```xml
<dependency>
    <groupId>com.amazonaws</groupId>
    <artifactId>aws-xray-recorder-sdk-spring</artifactId>
</dependency>
```

## Configuration Management

### Environment Variables

**ECS Task Definition**:
```json
{
  "environment": [
    { "name": "SPRING_PROFILES_ACTIVE", "value": "dev" },
    { "name": "CONFIG_SERVER_URL", "value": "http://config-server.local:8081" },
    { "name": "EUREKA_SERVER_URL", "value": "http://discovery-server.local:8082/eureka" },
    { "name": "RDS_ENDPOINT", "value": "sdt-dev-db.xxxxx.us-east-1.rds.amazonaws.com" },
    { "name": "MONGODB_HOST", "value": "mongodb.local" },
    { "name": "RABBITMQ_HOST", "value": "rabbitmq.local" },
    { "name": "REDIS_HOST", "value": "redis.local" }
  ],
  "secrets": [
    { "name": "DB_PASSWORD", "valueFrom": "arn:aws:secretsmanager:..." },
    { "name": "JWT_SECRET", "valueFrom": "arn:aws:secretsmanager:..." },
    { "name": "GOOGLE_CLIENT_SECRET", "valueFrom": "arn:aws:secretsmanager:..." }
  ]
}
```

### Secrets Management

All sensitive data stored in AWS Secrets Manager:
- Database passwords
- JWT secret
- OAuth client secrets
- API keys (Google API, not OpenAI)

**Sprint 3 Update**: Replaced OpenAI API key with Google API secret.

## Service Startup Order

**Critical Dependency Chain**:

1. **Config Server** (8081) - Must start first
   - Provides configuration to all services
   
2. **Discovery Server** (8082) - Must start second
   - Registers all services
   
3. **API Gateway** (8080) - Must start third
   - Routes to registered services
   
4. **Data Services** (MongoDB, RabbitMQ, Redis) - Start in parallel
   - Required by application services
   
5. **Application Services** - Start in parallel
   - user-service, task-service, etc.

**ECS Deployment**: Services start in parallel, but health checks ensure dependencies are ready.

## Testing

### Unit Tests

```java
@SpringBootTest
class UserServiceTest {
    @MockBean
    private UserRepository userRepository;
    
    @Autowired
    private UserService userService;
    
    @Test
    void testCreateUser() {
        // Test implementation
    }
}
```

### Integration Tests

```java
@SpringBootTest(webEnvironment = WebEnvironment.RANDOM_PORT)
@AutoConfigureTestDatabase
class UserControllerIntegrationTest {
    @Autowired
    private TestRestTemplate restTemplate;
    
    @Test
    void testGetUser() {
        ResponseEntity<User> response = restTemplate.getForEntity("/api/users/1", User.class);
        assertEquals(HttpStatus.OK, response.getStatusCode());
    }
}
```

### SonarQube Integration

**Sprint 3 Enhancement**: Automated code quality analysis

```xml
<plugin>
    <groupId>org.sonarsource.scanner.maven</groupId>
    <artifactId>sonar-maven-plugin</artifactId>
    <version>3.9.1.2184</version>
</plugin>
```

**Quality Gates**:
- Code coverage > 80%
- No critical bugs
- No security vulnerabilities
- Technical debt < 5%

## Performance Optimization

### Database Connection Pooling

```yaml
spring:
  datasource:
    hikari:
      maximum-pool-size: 10
      minimum-idle: 5
      connection-timeout: 30000
      idle-timeout: 600000
      max-lifetime: 1800000
```

### Caching

```java
@Cacheable(value = "users", key = "#id")
public User getUserById(Long id) {
    return userRepository.findById(id)
        .orElseThrow(() -> new ResourceNotFoundException("User not found"));
}
```

### Async Processing

```java
@Async
public CompletableFuture<Report> generateReport(Long userId) {
    // Long-running task
    return CompletableFuture.completedFuture(report);
}
```

## Security Best Practices

1. **No Hardcoded Secrets**: Use Secrets Manager
2. **Least Privilege**: IAM roles with minimal permissions
3. **Input Validation**: Validate all user inputs
4. **SQL Injection Prevention**: Use parameterized queries
5. **XSS Prevention**: Sanitize outputs
6. **CSRF Protection**: Enabled by default in Spring Security
7. **Rate Limiting**: Implemented in API Gateway
8. **Audit Logging**: Log all security events

## Troubleshooting

### Service Not Registering with Eureka

**Symptoms**: Service starts but not visible in Eureka dashboard

**Solutions**:
1. Verify `EUREKA_SERVER_URL` environment variable
2. Check security group allows traffic to port 8082
3. Verify service discovery DNS resolution
4. Check CloudWatch logs for connection errors

### Database Connection Failures

**Symptoms**: Service fails to start with database connection error

**Solutions**:
1. Verify RDS endpoint in environment variables
2. Check security group allows traffic from ECS to RDS
3. Verify database credentials in Secrets Manager
4. Check RDS instance is running

### RabbitMQ Connection Issues

**Symptoms**: Notification service can't connect to RabbitMQ

**Solutions**:
1. Verify RabbitMQ service is running in ECS
2. Check service discovery DNS: `rabbitmq.local`
3. Verify Erlang cookie in Secrets Manager
4. Check CloudWatch logs for permission errors

### Build Failures

**Symptoms**: Maven build fails with "Could not find artifact"

**Solutions** (Sprint 3 Fixes):
1. Build shared dependencies first: `common-event`, `common-security`, `common-util`
2. Use correct module paths: `skilltracker-common/common-security`
3. Build user-service before task-service (dependency)
4. Clear Maven cache: `mvn clean install -U`

## Best Practices

1. **Service Independence**: Each service should be independently deployable
2. **Database per Service**: No shared databases between services
3. **API Versioning**: Use `/api/v1/` prefix for versioning
4. **Idempotency**: Design APIs to be idempotent
5. **Circuit Breakers**: Use Resilience4j for fault tolerance
6. **Graceful Degradation**: Handle service failures gracefully
7. **Monitoring**: Instrument all services with metrics
8. **Documentation**: Keep API docs up-to-date

## Future Enhancements

1. **Event Sourcing**: Implement for audit trail
2. **CQRS**: Separate read and write models
3. **GraphQL**: Alternative to REST APIs
4. **gRPC**: For inter-service communication
5. **Service Mesh**: AWS App Mesh for advanced routing
6. **Chaos Engineering**: Test resilience with chaos experiments
7. **Multi-Region**: Deploy across multiple AWS regions

## References

- [Spring Boot Documentation](https://spring.io/projects/spring-boot)
- [Spring Cloud Documentation](https://spring.io/projects/spring-cloud)
- [Microservices Patterns](https://microservices.io/patterns/)
- [AWS ECS Best Practices](https://docs.aws.amazon.com/AmazonECS/latest/bestpracticesguide/)
