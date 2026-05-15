# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

You are an expert Python developer following Clean Architecture + DDD + TDD principles.

## Build Commands
```bash
# Full validation (run after changes) - MANDATORY before commits
/validate

# Auto-fix linting and formatting issues
/validate-fix

# Layer-specific tests (TDD workflow)
pytest tests/domain/ -v           # Domain (100% coverage)
pytest tests/application/ -v      # Application
pytest tests/infrastructure/ -v   # Infrastructure
pytest tests/presentation/ -v     # Presentation
pytest                            # Full suite

# Single test
pytest tests/domain/test_user.py -v
pytest tests/domain/ -k "test_validates_email" -v

# Individual tool runs
ruff check src/ tests/            # Linting
ruff format --check src/ tests/   # Format check
mypy src/                         # Type checking
pytest --cov=src --cov-report=term  # Coverage report
```

## Project Structure
```text
src/
├── domain/           # Pure Python: entities, value objects, specifications, errors
├── application/      # Pure Python: use cases, ports (interfaces), DTOs
├── infrastructure/   # Adapters, repositories, gateways, config loader
└── presentation/     # CLI, API controllers, entry points

tests/
├── domain/           # Unit tests (100% coverage)
├── application/      # Acceptance tests (mocked ports)
├── infrastructure/   # Integration tests (adapter contracts)
└── presentation/     # E2E tests (controllers/CLI)
```

## Task Delegation

For complex multi-layer tasks:
1. Break tasks to complexity ≤3 (Fibonacci scale)

## Clean Architecture Rules

**Dependency Rule**: Presentation → Infrastructure → Application → Domain (inward only)

| Layer | Allowed Imports | Forbidden |
|-------|-----------------|-----------|
| Domain (L1) | Kotlin stdlib only | application.*, infrastructure.*, presentation.*, external libs |
| Application (L2) | Domain | Infrastructure, Presentation, vendor SDKs |
| Infrastructure (L3) | Domain, Application ports | Presentation |
| Presentation (L4) | All (via DI) | Direct repository/hardware access |

### Layer Contents

- **Domain**: Entities (regular classes, NOT dataclasses), Value Objects (NewType), Specifications (business rules), Domain Errors, Enums
- **Application**: Use Cases (orchestration only), Ports (Protocol interfaces), DTOs
- **Infrastructure**: Repositories (DB), Adapters (external services), Gateways (APIs), Config loader
- **Presentation**: CLI commands, API controllers, Entry points (only place to unwrap Result)

### Import Convention

Use direct module imports, not package re-exports. Keep `__init__.py` files empty.
```python
# ✅ Correct
from domain.entities.user import User
from domain.specifications.payment_spec import PaymentValidationSpec

# ❌ Wrong
from domain.entities import User
from domain import User
```

## Result[T, E] Error Handling

All operations that can fail MUST return `Result[T, E]`. Uses the `returns` library.

### Layer Responsibilities

| Layer | Responsibility |
|-------|----------------|
| Domain | Define typed error hierarchy (`DomainError = Union[NotFoundError, ValidationError]`) |
| Infrastructure | Catch exceptions with `@safe`, convert to `Result` |
| Repository boundary | Transform infrastructure → domain errors via `map_failure` |
| Application (Use Cases) | Pure composition with `flow()`, `bind`, `map_`, `lash` — NO try-except |
| Presentation | Only layer permitted to unwrap with `unwrap()` or `value_or()` |
```python
// Infrastructure - catch exceptions here
@safe
def fetch_from_database(id: str) -> Entity:
    return db.query(id)

// Repository boundary - transform errors
def get_entity(id: str) -> Result[Entity, DomainError]:
    return fetch_from_database(id).map_failure(
        lambda _: NotFoundError(entity="Entity", id=id)
    )

// Use case - pure composition, NO try-except
def process_entity(id: str) -> Result[ProcessedEntity, DomainError]:
    return flow(
        get_entity(id),
        bind(validate_entity),
        map_(transform_to_output),
    )

// Presentation - unwrap here only
def handle_request(id: str) -> Response:
    result = process_entity(id)
    return result.map(to_success_response).value_or(to_error_response(result))
```

## TDD Workflow (MANDATORY)

**RED → GREEN → REFACTOR**: Write failing test → Run and see FAIL → Implement minimal code → Run and see PASS → Refactor

1. Write test FIRST (before any implementation)
2. Run test → Confirm RED (fails)
3. Write MINIMAL code to pass
4. Run test → Confirm GREEN (passes)
5. Refactor → Run tests after each change
6. Repeat for next test

**Layer-by-Layer TDD** (each layer MUST pass before next):
```bash
pytest tests/domain/ -v           # MUST PASS ✅
pytest tests/application/ -v      # MUST PASS ✅
pytest tests/infrastructure/ -v   # MUST PASS ✅
pytest tests/presentation/ -v     # MUST PASS ✅
/validate                         # Final validation ✅
```

**Gates**: PRE-CODE (have failing test?) → POST-TEST (saw it fail?) → POST-IMPL (passes now?) → POST-REFACTOR (still green?)

## Evidence-Driven Root Cause Analysis (Bug Fixes)

MANDATORY for all bug fixes: Follow this protocol to ensure fixes address root causes, not symptoms.

### Phase 1: Reproduce & Document
1. Create failing test that demonstrates the bug (TDD RED)
2. Document observed vs expected behavior with concrete evidence
3. Identify minimal reproduction steps

### Phase 2: Investigate Root Cause
1. Trace execution path - Use debugger/logging to follow data flow
2. Isolate the layer - Domain logic? Use case orchestration? Infrastructure mapping? Presentation state?
3. Check assumptions - Verify inputs, outputs, and state at each boundary
4. Find the root cause - Keep asking "why?" until you reach the architectural violation or logic error

### Phase 3: Fix & Verify
1. Fix at the correct layer - Don't patch symptoms in wrong layers
2. Run the failing test → Confirm GREEN
3. Run related tests - Check for regressions
4. Run `/validate` - Ensure fix doesn't violate quality gates

**Anti-Patterns**:
- ❌ Fixing symptoms without understanding root cause
- ❌ Adding workarounds in wrong layers (e.g., presentation fix for domain bug)
- ❌ Skipping reproduction test
- ❌ Assuming fix works without running tests

## Top 10 Architecture Rules

| # | Rule | Wrong | Correct |
|---|------|-------|---------|
| 1 | Entities | `@dataclass` | Regular class with factory methods |
| 2 | Business Rules | In use cases/controllers | Specifications in domain |
| 3 | Error Handling | try-except in use cases | `Result[T, E]` pattern |
| 4 | Interfaces | In infrastructure layer | Application layer owns ports (interfaces) |
| 5 | Infrastructure | Mixed concerns | Adapters (external), Repos (DB), Gateways (API) |
| 6 | Testing | Skip tests | TDD mandatory |
| 7 | Imports | Package re-exports | Direct module imports |
| 8 | Configuration | Scattered env vars | `myapp.yaml` via config port |
| 9 | Dependencies | Check later | Check `pyproject.toml` first |
| 10 | Short names | Fully qualified | `User` with import |

## Key Patterns

| Pattern | Location | Purpose |
|---------|----------|---------|
| Specification | `domain/specifications/` | Business rule encapsulation |
| Port/Adapter | `application/ports/`, `infrastructure/` | Dependency inversion |
| Result[T, E] | All layers | Explicit error handling |
| Configuration | `infrastructure/config/` | Load from `myapp.yaml` |

## Configuration

All runtime configuration values are read from `myapp.yaml` at the repository root.
```python
# Application port
class ConfigPort(Protocol):
    def get(self, key: str) -> Result[str, ConfigError]: ...

# Infrastructure adapter
class YamlConfigAdapter:
    def __init__(self, path: Path = Path("myapp.yaml")):
        self._config = yaml.safe_load(path.read_text())
```

## Quality Gates

### Pre-Implementation Gates
- [ ] Spec cross-check completed (requirements verified in `specs/`)
- [ ] Existing code searched: `rg "YourFeature" --type py`
- [ ] Library dependencies checked in `pyproject.toml`
- [ ] Feature is explicitly requested (YAGNI compliance)
- [ ] Failing test written FIRST (TDD RED phase)

### Code Quality Gates
- [ ] No fully qualified class names (use imports with short names)
- [ ] File size ≤500 lines
- [ ] Cognitive complexity within limits:

| Threshold | Scope | Rationale |
|-----------|-------|-----------|
| **10** | Standard methods | Default maximum for most code |
| **15** | Orchestration methods | Use cases, agents, and coordinators |
| **5** | Utility/helper functions | Keep simple functions simple |

- [ ] Clean Architecture layer dependencies verified
- [ ] No speculative or "just in case" code (YAGNI)
- [ ] All tests pass (TDD GREEN phase complete)

### Validation Gates (Mandatory)
Run `/validate` before committing. All gates must pass.

## Workflow Checklist

**Before implementing**:
1. Cross-check `specs/` for requirements (authoritative source)
2. Search existing code: `rg "YourFeature" --type py`
3. Check `pyproject.toml` for libraries

**Implementation order** (TDD each layer):
1. Domain → test → validate
2. Application → test → validate
3. Infrastructure → test → validate
4. Presentation → test → validate
5. Final: `/validate`

**Layer placement**:
- Business rule → Domain specification
- Workflow → Application use case
- External service → Infrastructure adapter
- Persistence → Infrastructure repository
- External API → Infrastructure gateway
- CLI/API → Presentation controller
- UI → Presentation ViewModel

## Critical Constraints

**NEVER**:
- Write code before failing test exists
- Use `@dataclass` for domain entities
- Put business logic in use cases
- Import outer layers from inner
- Use try-except in use cases
- Skip `/validate` before commits
- Exceed 500 lines/file
- Use package re-exports in imports

**ALWAYS**:
- TDD: test first, see red, implement, see green
- Cross-check `specs/` before implementation
- Use `Result[T, E]` for fallible operations
- Validate with `/validate`
- Use direct module imports
- Keep `__init__.py` files empty
- Get plan approval before code changes

## Tech Stack

- **Language**: Python 3.11+
- **Type Checking**: mypy (strict mode)
- **Linting/Formatting**: ruff
- **Testing**: pytest + pytest-cov
- **Error Handling**: returns library (`Result[T, E]`)
- **Configuration**: PyYAML (myapp.yaml)
- **Architecture**: Clean Architecture + DDD + TDD

## Active Technologies
- Python 3.11+ + mcp (FastMCP), httpx, beautifulsoup4, playwright, pdfplumber, python-docx, openpyxl, pyyaml (001-mcp-server)
- N/A (stateless tools, configuration via YAML file) (001-mcp-server)

## Recent Changes
- None

## GSD Planning Lifecycle

Planning documents in `.planning/` should be tracked in git during active work but cleaned up after completion:

- **During active phase**: `.planning/` files are committed to track planning decisions
- **After plan completion**: Delete `.planning/phases/` directories for completed work (keeps git history but removes clutter)
- **PROJECT.md, ROADMAP.md, REQUIREMENTS.md**: Keep until milestone complete, then archive or delete
- **Goal**: Planning docs exist in git history for reference but don't accumulate in working directory

To enable this, `.gitignore` has `!.planning/` exception to override `*.md` ignore rule.
