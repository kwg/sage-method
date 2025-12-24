# Test Project: URL Shortener API

**Purpose**: End-to-end validation of SAGE orchestration lifecycle

---

## Project Brief

A minimal URL shortener REST API for validating the SAGE lifecycle. This is a **test project** - the goal is to exercise all orchestration phases, not to build a production service.

### Core Features

1. **Shorten URL**: `POST /api/shorten`
   - Input: `{ "url": "https://example.com/very/long/path" }`
   - Output: `{ "id": "abc123", "short_url": "http://localhost:3000/abc123" }`
   - Validates URL format
   - Generates 6-character alphanumeric ID

2. **Redirect**: `GET /:id`
   - Redirects to original URL (302)
   - Increments click counter
   - Returns 404 if ID not found

3. **Stats**: `GET /api/stats/:id`
   - Returns: `{ "id": "abc123", "original_url": "...", "clicks": 42, "created_at": "..." }`
   - Returns 404 if ID not found

### Technical Constraints

- **Language**: TypeScript (Node.js)
- **Framework**: Express.js (minimal dependencies)
- **Storage**: In-memory Map (no database - keeps it simple)
- **Testing**: Jest with supertest
- **No auth**: Public endpoints for simplicity

### Out of Scope

- Custom short codes
- URL expiration
- User accounts
- Analytics dashboard
- Rate limiting
- Persistent storage

---

## Expected Artifacts

### Phase 1: Design
- Product brief (this document serves as input)
- Research summary (tech stack validation)

### Phase 2: Plan
- PRD with acceptance criteria
- Architecture doc (simple - just API structure)
- 3-4 stories covering the endpoints + tests

### Phase 3: Build
- `src/index.ts` - Express app entry
- `src/routes.ts` - Route handlers
- `src/store.ts` - In-memory storage
- `src/utils.ts` - ID generation, URL validation
- `tests/*.test.ts` - Integration tests

### Phase 4: Validate
- All tests passing
- Manual curl verification
- Epic completion summary

---

## Success Criteria

1. All SAGE lifecycle phases execute without manual intervention (except HitL approvals)
2. GitHub issues created for HitL breakpoints
3. Checkpoints written and resumable
4. At least one parallel task batch executed
5. Clean epic completion signal

---

## Test Execution Notes

This project is intentionally small to complete in a single session. Expected timeline:
- Phase 1: ~5 minutes (brief already provided)
- Phase 2: ~10 minutes (PRD + simple arch + stories)
- Phase 3: ~20 minutes (implementation + tests)
- Phase 4: ~5 minutes (validation)

Total: ~40 minutes of orchestration time (excluding HitL wait times)
