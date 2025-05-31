```markdown
## System Patterns (systemPatterns.md)

This document outlines the system patterns employed in the TaskMate project, focusing on architectural design, data models, API definitions, component structure, integration points, and scalability strategies for the notification, task filtering, and user experience improvements.

### 1. Architectural Design

We will employ a **Microservices architecture** with an **Event-Driven** approach for enhanced modularity, scalability, and fault isolation. This approach allows independent deployment and scaling of individual services responsible for notifications, task filtering, and user experience aspects.

*   **Notification Service:** Handles sending and managing notifications.
*   **Task Filtering Service:**  Manages and applies task filters.
*   **User Experience (UX) Service:**  Handles user interface and interaction related to notifications and filtering.
*   **API Gateway:** Acts as a single entry point for all client requests, routing them to the appropriate microservice.
*   **Event Bus (Message Queue):** Facilitates asynchronous communication between microservices.  We will use RabbitMQ or Kafka for this purpose.

**Justification:**

*   **Scalability:** Each service can be scaled independently based on its specific needs.
*   **Fault Isolation:** Failure in one service does not necessarily affect other services.
*   **Modularity:** Allows for independent development and deployment of services.
*   **Technology Diversity:** Enables the use of different technologies for different services based on their requirements.

### 2. Data Models

The following are key data models utilized within the system:

*   **User:**
    *   `userId` (UUID): Unique identifier for the user.
    *   `username` (String): User's username.
    *   `email` (String): User's email address.
    *   `notificationPreferences` (JSON): User's preferences for notifications (e.g., types of notifications, delivery methods).

*   **Task:**
    *   `taskId` (UUID): Unique identifier for the task.
    *   `title` (String): Task title.
    *   `description` (String): Task description.
    *   `assigneeId` (UUID): User ID of the assignee.
    *   `dueDate` (Date): Task due date.
    *   `status` (Enum): Task status (e.g., Open, In Progress, Completed).
    *   `priority` (Enum): Task priority (e.g., High, Medium, Low).
    *   `tags` (Array of Strings): Task tags.

*   **Notification:**
    *   `notificationId` (UUID): Unique identifier for the notification.
    *   `userId` (UUID): User ID the notification is for.
    *   `taskId` (UUID, optional): Task ID related to the notification (if applicable).
    *   `type` (Enum): Notification type (e.g., TaskAssigned, TaskDue, TaskUpdated).
    *   `message` (String): Notification message.
    *   `createdDate` (Date): Date the notification was created.
    *   `read` (Boolean): Indicates whether the notification has been read.
    *   `deliveryMethod` (Enum): The method used to deliver the notification (e.g., Push, Email, In-App).

*   **Filter:**
    *   `filterId` (UUID): Unique identifier for the filter.
    *   `userId` (UUID): User ID associated with the filter.
    *   `name` (String): Filter name.
    *   `criteria` (JSON): Filter criteria (e.g., status = "Open", priority = "High", assigneeId = current user).
    *   `type` (Enum): The type of filter (e.g., Task, User).

**Database Considerations:**

*   Each microservice will have its own dedicated database.  We might use PostgreSQL for its robustness and support for JSON data types for `notificationPreferences` and `criteria`.
*   Consider using a NoSQL database like MongoDB for the Notification Service if high write throughput and flexible schema are prioritized.

### 3. API Definitions

The following APIs will be exposed by the microservices:

*   **Notification Service API:**
    *   `POST /notifications`: Create a new notification.
        *   Request Body:  `Notification` object (excluding `notificationId`)
        *   Response:  `Notification` object with `notificationId`.
    *   `GET /notifications/{userId}`: Get all notifications for a user.
        *   Response:  Array of `Notification` objects.
    *   `PUT /notifications/{notificationId}/read`: Mark a notification as read.
        *   Response:  Success/Failure indication.
    *   `GET /notifications/unread/{userId}`: Get the number of unread notifications for a user.
        *   Response: Number of unread notifications
    *   `PUT /notifications/preferences/{userId}`: Update user notification preferences.
        *   Request Body: `notificationPreferences` JSON object.
        *   Response: Success/Failure indication.

*   **Task Filtering Service API:**
    *   `POST /filters`: Create a new filter.
        *   Request Body: `Filter` object (excluding `filterId`).
        *   Response: `Filter` object with `filterId`.
    *   `GET /filters/{filterId}`: Get a specific filter.
        *   Response: `Filter` object.
    *   `GET /filters/user/{userId}`: Get all filters for a user.
        *   Response: Array of `Filter` objects.
    *   `PUT /filters/{filterId}`: Update an existing filter.
        *   Request Body: `Filter` object.
        *   Response: Success/Failure indication.
    *   `DELETE /filters/{filterId}`: Delete a filter.
        *   Response: Success/Failure indication.
    *   `POST /tasks/filtered`: Returns filtered tasks based on filter criteria
        *   Request Body: `criteria` JSON object (from a `Filter` object) and pagination parameters.
        *   Response: Array of `Task` objects.

*   **UX Service API (Aggregated through API Gateway):**
    *   These APIs will primarily be used to orchestrate calls to the other microservices and transform the responses for the UI.  They will likely expose endpoints like:
        *   `GET /user/notifications`:  Returns user notifications with task details.
        *   `GET /user/filters`: Returns user filters.
        *   `POST /user/tasks/filtered`: Returns filtered tasks for the user.
        *   `PUT /user/notifications/{notificationId}/read`: Mark a notification as read.

**API Style:**

*   RESTful APIs using JSON for request and response bodies.
*   Standard HTTP status codes for indicating success and errors.
*   Authentication and authorization via JWT tokens.

### 4. Component Structure

Each microservice will be structured as follows:

*   **Controller Layer:** Handles incoming HTTP requests and routes them to the appropriate service.
*   **Service Layer:** Contains the business logic for the microservice.
*   **Data Access Layer (Repository):** Interacts with the database.
*   **Configuration:**  Handles configuration settings for the microservice.
*   **Models:** Defines the data models used by the microservice.
*   **Events:** Defines the events that the microservice publishes and consumes.

**Example - Notification Service:**

```
notification-service/
├── src/
│   ├── main/
│   │   ├── java/
│   │   │   ├── com/taskmate/notification/
│   │   │   │   ├── controller/
│   │   │   │   │   └── NotificationController.java
│   │   │   │   ├── service/
│   │   │   │   │   └── NotificationService.java
│   │   │   │   ├── repository/
│   │   │   │   │   └── NotificationRepository.java
│   │   │   │   ├── model/
│   │   │   │   │   └── Notification.java
│   │   │   │   ├── config/
│   │   │   │   │   └── NotificationConfig.java
│   │   │   │   ├── events/
│   │   │   │   │   └── TaskUpdatedEvent.java // Example of an event
│   │   │   │   └── Application.java
│   │   ├── resources/
│   │   │   └── application.properties
│   └── test/
│       └── ...
├── pom.xml (Maven) or build.gradle (Gradle)
└── Dockerfile (for containerization)

```

### 5. Integration Points

*   **Event Bus (RabbitMQ/Kafka):**
    *   The Notification Service will subscribe to events such as `TaskAssigned`, `TaskUpdated`, and `TaskDue` to trigger notifications.
    *   Other services might publish events that the UX Service consumes to update the UI.

*   **API Gateway:**
    *   All client requests will be routed through the API Gateway.
    *   The API Gateway will handle authentication, authorization, and rate limiting.

*   **Database Integration:**
    *   Each microservice will interact with its own dedicated database.
    *   Consider using a common data access library or framework to ensure consistency.

*   **Logging and Monitoring:**
    *   All microservices will be integrated with a centralized logging and monitoring system (e.g., ELK stack, Prometheus/Grafana).

### 6. Scalability Strategy

*   **Horizontal Scaling:**  Each microservice can be scaled horizontally by deploying multiple instances behind a load balancer.
*   **Database Sharding:**  For very large datasets, consider sharding the databases to distribute the load.
*   **Caching:**  Implement caching at various layers (e.g., API Gateway, Service Layer) to reduce database load and improve performance. Redis or Memcached are suitable options.
*   **Asynchronous Processing:** Utilize message queues (RabbitMQ/Kafka) for asynchronous tasks like sending notifications, preventing blocking operations and improving responsiveness.
*   **Containerization and Orchestration:** Use Docker for containerization and Kubernetes for orchestration to automate deployment, scaling, and management of the microservices.
*   **Monitoring and Alerting:**  Implement comprehensive monitoring and alerting to identify performance bottlenecks and proactively address issues.

Created on 31.05.2025
```