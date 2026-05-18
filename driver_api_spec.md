# SmartBus Driver App — API Specification

This document provides a comprehensive specification of all backend endpoints designed for the **Driver Application**. It covers:
1. **Global Configuration & Authentication**
2. **Authentication Flow**
3. **Trip Lifecycle Management**
4. **Ticket Scanning & Real-Time Validation**
5. **Offline Synchronization & Reconciliation**

---

## 1. Global Configuration & Security

### Base URL
By default, the backend API is hosted at:
`http://<server-ip-or-domain>/api` (or custom port, e.g., `http://localhost:3000`)

### Security & Role Authorization
* Most driver endpoints are protected by NestJS Guards.
* The driver **must** pass a JSON Web Token (JWT) in the headers for all protected endpoints.
* The JWT contains the driver's identity (`sub` as `userId`, `role` as `DRIVER`).
* If the user role is not `DRIVER` (e.g., `PASSENGER`), protected driver endpoints will return `403 Forbidden`.

### Global Headers
For all endpoints after login:
```http
Authorization: Bearer <JWT_ACCESS_TOKEN>
Content-Type: application/json
Accept: application/json
```

---

## 2. Authentication Flow

Drivers must authenticate to obtain a JWT access token and a refresh token.

### 2.1 Driver Login
Allows the driver to log into the application using their phone number, email, or FID identifier.

* **Route:** `POST /auth/login`
* **Access:** `Public`
* **Request Format (JSON):**
  ```json
  {
    "identifier": "+251912345678",
    "identifierType": "PHONE",
    "password": "SecurePassword123"
  }
  ```
  * `identifier`: Driver's phone number, email, or FID string.
  * `identifierType`: Enum value of `PHONE`, `EMAIL`, or `FID`.
  * `password`: The plain-text password.

* **Success Response (`200 OK`):**
  ```json
  {
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJkODU3MzhmOC00NzM4LTRjOWYtOWZlZS0wMmRhNWQwYzg1ZDAiLCJyb2xlIjoiRFJJVkVSIiwicGhvbmUiOiIrMjUxOTEyMzQ1Njc4IiwiaWF0IjoxNzg0NDM4NDAwLCJleHAiOjE3ODQ0MzkzMDB9...",
    "refreshToken": "7c8e6a1005b8a07c92a6a12b4e859bcf69a2d3e4f...",
    "user": {
      "id": "d85738f8-4738-4c9f-9fee-02da5d0c85d0",
      "role": "DRIVER",
      "status": "ACTIVE",
      "fullName": "Abebe Bikila",
      "phone": "+251912345678",
      "email": "abebe@smartbus.et",
      "fid": null
    }
  }
  ```
* **Error Responses:**
  * `401 Unauthorized`: `"Invalid credentials"`
  * `403 Forbidden`: `"Account is disabled"` or `"Please verify your phone first"`

---

### 2.2 Token Rotation / Refresh
Used by the driver app to obtain a new `accessToken` when the old one expires (typically after 15 minutes) without forcing the driver to log in again.

* **Route:** `POST /auth/refresh`
* **Access:** `Public`
* **Request Format (JSON):**
  ```json
  {
    "refreshToken": "7c8e6a1005b8a07c92a6a12b4e859bcf69a2d3e4f..."
  }
  ```
* **Success Response (`200 OK`):**
  Returns a brand new `accessToken` and a rotated `refreshToken`.
  ```json
  {
    "accessToken": "newAccessTokenValue...",
    "refreshToken": "newRefreshTokenValue...",
    "user": {
      "id": "d85738f8-4738-4c9f-9fee-02da5d0c85d0",
      "role": "DRIVER",
      "status": "ACTIVE",
      "fullName": "Abebe Bikila",
      "phone": "+251912345678",
      "email": "abebe@smartbus.et",
      "fid": null
    }
  }
  ```
* **Error Responses:**
  * `401 Unauthorized`: `"Invalid refresh token"`, `"Refresh token expired"`, or `"Refresh token replay detected"` (security breach lockout).

---

### 2.3 Logout
Revokes the refresh token, logging the driver out.

* **Route:** `POST /auth/logout`
* **Headers:** `Authorization: Bearer <JWT_ACCESS_TOKEN>`
* **Request Format (JSON):**
  ```json
  {
    "refreshToken": "newRefreshTokenValue..."
  }
  ```
* **Success Response (`204 No Content`):**
  Empty body. Refresh token is invalidated in the database.

---

## 3. Trip Lifecycle Management

Drivers are assigned scheduled trips. The driver app uses these endpoints to view assignments, start an assigned trip, and mark a trip completed.

### 3.1 List Assigned Trips
Retrieves a paginated list of trips assigned to the logged-in driver, filterable by status and date range.

* **Route:** `GET /trips`
* **Headers:** `Authorization: Bearer <JWT_ACCESS_TOKEN>`
* **Query Parameters:**
  * `page` (optional): Page number, default `1`.
  * `limit` (optional): Items per page (1 to 100), default `20`.
  * `status` (optional): Filter by `TripStatus` enum: `SCHEDULED`, `IN_PROGRESS`, `COMPLETED`, `CANCELLED`.
  * `fromDate` (optional): Filter scheduled start from this date (ISO 8601 string, e.g., `2026-05-18T00:00:00Z`).
  * `toDate` (optional): Filter scheduled start up to this date (ISO 8601 string, e.g., `2026-05-18T23:59:59Z`).
  * `sortBy` (optional): Sort fields: `scheduledFor`, `createdAt`, `startedAt`, `endedAt`. Default is `scheduledFor`.
  * `sortOrder` (optional): Sort direction: `asc` or `desc`. Default is `desc`.

* **Success Response (`200 OK`):**
  ```json
  {
    "items": [
      {
        "id": "e0bfa99b-0072-4d22-b5e1-512c0199e52e",
        "routeId": "7df41da8-d421-4b10-85f2-cb8a99db324b",
        "driverId": "d85738f8-4738-4c9f-9fee-02da5d0c85d0",
        "busIdentifier": "Bus-049",
        "status": "SCHEDULED",
        "startedAt": null,
        "endedAt": null,
        "scheduledFor": "2026-05-18T14:30:00.000Z",
        "createdAt": "2026-05-17T09:00:00.000Z",
        "updatedAt": "2026-05-17T09:00:00.000Z",
        "route": {
          "id": "7df41da8-d421-4b10-85f2-cb8a99db324b",
          "routeNumber": "R-10",
          "name": "Mexico Square to Bole"
        },
        "passengerCount": 0
      }
    ],
    "meta": {
      "totalItems": 1,
      "itemCount": 1,
      "itemsPerPage": 20,
      "totalPages": 1,
      "currentPage": 1
    }
  }
  ```

---

### 3.2 Get Trip Details & Statistics
Fetches a detailed view of a single trip, including its route details and a real-time validation scan summary.

* **Route:** `GET /trips/:id`
* **Headers:** `Authorization: Bearer <JWT_ACCESS_TOKEN>`
* **Route Params:**
  * `id`: The UUID of the trip.
* **Success Response (`200 OK`):**
  ```json
  {
    "id": "e0bfa99b-0072-4d22-b5e1-512c0199e52e",
    "routeId": "7df41da8-d421-4b10-85f2-cb8a99db324b",
    "driverId": "d85738f8-4738-4c9f-9fee-02da5d0c85d0",
    "busIdentifier": "Bus-049",
    "status": "IN_PROGRESS",
    "startedAt": "2026-05-18T14:35:12.000Z",
    "endedAt": null,
    "scheduledFor": "2026-05-18T14:30:00.000Z",
    "createdAt": "2026-05-17T09:00:00.000Z",
    "updatedAt": "2026-05-18T14:35:12.000Z",
    "route": {
      "id": "7df41da8-d421-4b10-85f2-cb8a99db324b",
      "routeNumber": "R-10",
      "name": "Mexico Square to Bole"
    },
    "summary": {
      "totalScans": 34,
      "validScans": 30,
      "expiredScans": 2,
      "alreadyUsedScans": 1,
      "invalidSignatureScans": 1,
      "inspectionScans": 0
    },
    "passengerCount": 30
  }
  ```
* **Error Responses:**
  * `404 Not Found`: `"Trip not found"` (if the trip does not exist or belongs to another driver).

---

### 3.3 Start a Scheduled Trip
Transitions an assigned trip's status from `SCHEDULED` to `IN_PROGRESS`.

* **Route:** `PATCH /trips/:id/start`
* **Headers:** `Authorization: Bearer <JWT_ACCESS_TOKEN>`
* **Route Params:**
  * `id`: The UUID of the trip.
* **Success Response (`200 OK`):**
  ```json
  {
    "id": "e0bfa99b-0072-4d22-b5e1-512c0199e52e",
    "routeId": "7df41da8-d421-4b10-85f2-cb8a99db324b",
    "driverId": "d85738f8-4738-4c9f-9fee-02da5d0c85d0",
    "busIdentifier": "Bus-049",
    "status": "IN_PROGRESS",
    "startedAt": "2026-05-18T14:35:12.000Z",
    "endedAt": null,
    "scheduledFor": "2026-05-18T14:30:00.000Z",
    "createdAt": "2026-05-17T09:00:00.000Z",
    "updatedAt": "2026-05-18T14:35:12.000Z",
    "route": {
      "id": "7df41da8-d421-4b10-85f2-cb8a99db324b",
      "routeNumber": "R-10",
      "name": "Mexico Square to Bole"
    }
  }
  ```
* **Error Responses:**
  * `400 Bad Request`: `"Cannot start a trip in IN_PROGRESS status"`
  * `404 Not Found`: `"Trip not found"`
  * `409 Conflict`: `"Driver already has an in-progress trip"` (the driver must end their active trip first).

---

### 3.4 End an In-Progress Trip
Transitions an active trip's status from `IN_PROGRESS` to `COMPLETED` and calculates final validation metrics.

* **Route:** `PATCH /trips/:id/end`
* **Headers:** `Authorization: Bearer <JWT_ACCESS_TOKEN>`
* **Route Params:**
  * `id`: The UUID of the trip.
* **Success Response (`200 OK`):**
  ```json
  {
    "id": "e0bfa99b-0072-4d22-b5e1-512c0199e52e",
    "routeId": "7df41da8-d421-4b10-85f2-cb8a99db324b",
    "driverId": "d85738f8-4738-4c9f-9fee-02da5d0c85d0",
    "busIdentifier": "Bus-049",
    "status": "COMPLETED",
    "startedAt": "2026-05-18T14:35:12.000Z",
    "endedAt": "2026-05-18T15:20:45.000Z",
    "scheduledFor": "2026-05-18T14:30:00.000Z",
    "createdAt": "2026-05-17T09:00:00.000Z",
    "updatedAt": "2026-05-18T15:20:45.000Z",
    "route": {
      "id": "7df41da8-d421-4b10-85f2-cb8a99db324b",
      "routeNumber": "R-10",
      "name": "Mexico Square to Bole"
    },
    "summary": {
      "totalScans": 34,
      "validScans": 30,
      "expiredScans": 2,
      "alreadyUsedScans": 1,
      "invalidSignatureScans": 1,
      "inspectionScans": 0
    },
    "passengerCount": 30
  }
  ```
* **Error Responses:**
  * `400 Bad Request`: `"Cannot end a trip in COMPLETED status"`
  * `404 Not Found`: `"Trip not found"`

---

## 4. Ticket Scanning & Real-Time Validation

When boarding a passenger, the driver scans the QR code presented by the passenger app. The driver app immediately submits this payload to the server for online validation.

### 4.1 Validate Passenger Ticket (Online)
Verifies the cryptographic signature of the QR code, checks validity criteria (status, expiry time), and marks it as `USED` atomically to prevent double boarding.

* **Route:** `POST /tickets/validate`
* **Headers:** `Authorization: Bearer <JWT_ACCESS_TOKEN>`
* **Request Format (JSON):**
  ```json
  {
    "qrPayload": "{\"ticketId\":\"c4974f26-0d12-4217-bfbe-d88562d5f04b\",\"passengerId\":\"a38fa721-0072-4d22-b5e1-512c0199e52e\",\"routeId\":\"7df41da8-d421-4b10-85f2-cb8a99db324b\"}",
    "qrSignature": "MEYCIQCcL33B76x/M4D77oKz...",
    "inspectionMode": false
  }
  ```
  * `qrPayload`: The raw, JSON-encoded passenger ticket payload.
  * `qrSignature`: Cryptographic HMAC/signature verifying that the payload was generated by the backend and not tampered with.
  * `inspectionMode` (optional, default `false`): If `true`, verifies the ticket's signature, expiry, and state but **does not** transition the ticket status to `USED` (used by transit ticket inspectors).

* **Success Response (`200 OK` — Valid Ticket):**
  ```json
  {
    "result": "VALID",
    "ticket": {
      "id": "c4974f26-0d12-4217-bfbe-d88562d5f04b",
      "status": "USED",
      "fareAmount": 12.50,
      "purchasedAt": "2026-05-18T14:10:00.000Z",
      "expiresAt": "2026-05-18T15:10:00.000Z",
      "passengerId": "a38fa721-0072-4d22-b5e1-512c0199e52e",
      "route": {
        "routeNumber": "R-10",
        "name": "Mexico Square to Bole"
      },
      "boardingStop": {
        "name": "Mexico Square Stop"
      },
      "dropoffStop": {
        "name": "Bole High School Stop"
      }
    },
    "passenger": {
      "fullName": "Dawit Abraham"
    },
    "scannedAt": "2026-05-18T14:38:22.105Z",
    "isInspection": false
  }
  ```

* **Failed / Error Responses:**
  * `400 Bad Request`:
    * `"Invalid QR signature"`: The ticket has been forged or altered.
    * `"Malformed QR payload"`: JSON payload failed parsing.
    * `"Ticket not found"`: The ticket UUID is not in the system.
  * `409 Conflict`:
    * Indicates double boarding. The ticket has already been used.
    ```json
    {
      "statusCode": 409,
      "message": {
        "result": "ALREADY_USED",
        "ticket": { ... },
        "passenger": { "fullName": "Dawit Abraham" },
        "scannedAt": "2026-05-18T14:38:22.105Z",
        "isInspection": false
      },
      "error": "Conflict"
    }
    ```
  * `410 Gone`:
    * Indicates ticket expiration (tickets are valid for 60 minutes after purchase).
    ```json
    {
      "statusCode": 410,
      "message": {
        "result": "EXPIRED",
        "ticket": { ... },
        "passenger": { "fullName": "Dawit Abraham" },
        "scannedAt": "2026-05-18T14:38:22.105Z",
        "isInspection": false
      },
      "error": "Gone"
    }
    ```

---

### 4.2 List Scanned Passengers for Trip
Retrieves a paginated list of all passengers successfully scanned during a specific trip. Contains a duplicate indicator.

* **Route:** `GET /trips/:tripId/scans`
* **Headers:** `Authorization: Bearer <JWT_ACCESS_TOKEN>`
* **Route Params:**
  * `tripId`: The UUID of the trip.
* **Query Parameters:**
  * `page` (optional): default `1`.
  * `limit` (optional): default `20`.

* **Success Response (`200 OK`):**
  ```json
  {
    "items": [
      {
        "id": "76dfaa02-e289-42b7-a359-eb012674e2d3",
        "result": "VALID",
        "scannedAt": "2026-05-18T14:40:10.000Z",
        "isInspection": false,
        "passenger": {
          "fullName": "Marta Kebede"
        },
        "ticket": {
          "id": "f5a77b81-a982-45e3-a5bc-cd1923cb82fa",
          "fareAmount": 12.50
        },
        "isPreviouslySeen": false
      }
    ],
    "meta": {
      "totalItems": 1,
      "itemCount": 1,
      "itemsPerPage": 20,
      "totalPages": 1,
      "currentPage": 1
    }
  }
  ```
  * `isPreviouslySeen`: A critical warning flag. Returns `true` if this passenger's ticket was scanned multiple times during the active trip (assists driver in detecting multi-passenger bypass or ticket pass-back fraud).

---

## 5. Offline Synchronization & Reconciliation

For operations in areas with weak or no network, the driver app performs ticket verification **offline** on the client (using local public keys or HMAC secrets). Once back online, the driver app batches the stored scan events and syncs them to the server for reconciliation.

### 5.1 Batch Sync Offline Validations
Sends a batch of offline scan events recorded on the driver's device to the backend. The backend processes each scan, updates ticket statuses, registers the offline events, and compiles a comprehensive reconciliation report identifying anomalies.

* **Route:** `POST /sync/validations`
* **Headers:** `Authorization: Bearer <JWT_ACCESS_TOKEN>`
* **Request Format (JSON):**
  ```json
  {
    "scans": [
      {
        "qrPayload": "{\"ticketId\":\"c4974f26-0d12-4217-bfbe-d88562d5f04b\",\"passengerId\":\"a38fa721-0072-4d22-b5e1-512c0199e52e\",\"routeId\":\"7df41da8-d421-4b10-85f2-cb8a99db324b\"}",
        "qrSignature": "MEYCIQCcL33B76x/M4D77oKz...",
        "scannedAt": "2026-05-18T13:42:00.000Z",
        "inspectionMode": false,
        "localResult": "VALID"
      }
    ]
  }
  ```
  * `scans`: Array of offline scans (Minimum: 1, Maximum: 100).
  * `scannedAt`: The UTC ISO 8601 timestamp when the scan physically occurred in the bus.
  * `localResult` (optional): The result of the client-side validation logic at scan time (`VALID`, `EXPIRED`, `ALREADY_USED`, `INVALID_SIGNATURE`, etc.).

* **Success Response (`200 OK`):**
  ```json
  {
    "totalReceived": 1,
    "processed": 1,
    "failed": 0,
    "anomalies": 0,
    "results": [
      {
        "qrPayload": "{\"ticketId\":\"c4974f26-0d12-4217-bfbe-d88562d5f04b\",\"passengerId\":\"a38fa721-0072-4d22-b5e1-512c0199e52e\",\"routeId\":\"7df41da8-d421-4b10-85f2-cb8a99db324b\"}",
        "serverResult": "VALID",
        "localResult": "VALID",
        "action": "MARKED_USED",
        "ticketId": "c4974f26-0d12-4217-bfbe-d88562d5f04b",
        "anomaly": null
      }
    ]
  }
  ```

### Reconcile Action Types (`action`)
The reconciliation engine calculates a state-machine resolution action for every offline scan item:
1. `MARKED_USED`: Ticket was active online, now successfully updated to used as of the offline scan time.
2. `ALREADY_USED_SERVER_WINS`: Ticket was already marked as used on the server *before* this offline scan occurred. The offline scan is marked duplicate, server state stands.
3. `ALREADY_USED_OFFLINE_WINS`: The ticket is marked used on the server, but the offline scan happened *earlier* than the online scan record. The server updates the ticket's `usedAt` date to honor the earlier offline scan.
4. `EXPIRED`: The ticket was already expired at the time the offline scan was registered.
5. `INVALID`: Failed signature validation, or ticket did not exist.
6. `INSPECTION_LOGGED`: An offline inspection scan was successfully written to the audit log.
7. `IDEMPOTENT_SKIP`: Re-sync protection. The scan has already been synced previously and was skipped to prevent duplicate records.

### Reconcile Anomalies (`anomaly`)
Anomalies assist admins in identifying fraud or clock synchronization problems:
1. `CROSS_DEVICE_DUPLICATE`: The ticket was scanned on multiple distinct driver devices. Suggests passenger double-boarding or code sharing.
2. `TIME_DISCREPANCY`: The sync request arrived more than 24 hours after the scan occurred (suggests delayed syncing or device time manipulation).
3. `RESULT_MISMATCH`: The client validated the ticket offline (e.g. `VALID`), but the server resolved it differently (e.g. `EXPIRED` or `ALREADY_USED`). Indicates client database staleness or validation bypasses.
