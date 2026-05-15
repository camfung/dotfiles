> The fundamental laws governing all SpecKit development. These principles are non-negotiable.

# MyApp Constitution

A description of MyApp's purpose.

## Core Principles

### I. Clean Architecture Dependency Rule

Dependencies MUST point inward only: Presentation → Data → Application → Domain

**Import Conventions**:
- Use direct module imports: `from domain.entities.user import User`
- Do NOT use package re-exports: `from domain.entities import User`
- Keep `__init__.py` files empty (or minimal with `__all__` only)
- This makes dependency violations immediately visible in import statements

Non-Negotiable Rules:
- Domain (L1): Pure Python ONLY. ZERO dependencies on outer layers. No direct module imports or package imports permitted.
- Application (L2): Depends ONLY on Domain. Pure orchestration logic. No data/presentation implementations or vendor SDKs.
- Infrastructure (L3): Depends ONLY on Domain + Application ports. Infrastructure implementations permitted. No presentation layer access.
- Presentation (L4): May depend on all layers for DI binding only. UI/ViewModels must not contain business logic.

Rationale: Enforces testability, maintainability. Inner layers remain stable while outer layers can change independently.

### II. Specification Pattern for Business Logic

All domain validation and business rules MUST be encapsulated in Specification classes within domain/specifications/.

Non-Negotiable Rules: - Business logic MUST NOT reside in use cases, ViewModels, or repositories - Entities MUST be regular classes (NOT data classes) with factory methods and ID-based equality - Specifications MUST be independently testable with 100% coverage

Rationale: Centralizes business rules for reuse, testing, and auditability. Prevents logic duplication across layers.

### III. Result[T, E] Error Handling

All operations that can fail MUST return Result[T, E]. Bare try-except blocks are FORBIDDEN in use cases.
Non-Negotiable Rules:

Use cases MUST return Result[T, DomainError] using domain-specific error union types
Exceptions MUST be caught at infrastructure boundaries (data layer) using the @safe decorator and converted to Result
Infrastructure errors MUST be transformed to domain errors using map_failure before crossing into the domain layer
Error propagation MUST use flow(), bind, map_, or lash combinators
Use cases MUST NOT contain try-except blocks
Unwrapping (unwrap(), value_or()) is ONLY permitted at the presentation layer (controllers, CLI entry points)

### IV. SOLID PRINCIPLES

SOLID principles form the foundation of clean architecture.

#### Single Responsibility Principle (SRP)

Each class should have one reason to change. Separate responsibilities into different classes/modules.

#### Open/Closed Principle (OCP)

Software entities should be open for extension but closed for modification. Use interfaces and polymorphism to add behavior without changing existing code.

#### Liskov Substitution Principle (LSP)

Objects should be replaceable with their subtypes without breaking the program. Implementations must honor the contract defined by their interface.

#### Interface Segregation Principle (ISP)

Clients shouldn't be forced to depend on interfaces they don't use. Prefer small, focused interfaces over large, monolithic ones.

#### Dependency Inversion Principle (DIP)

High-level modules shouldn't depend on low-level modules. Both should depend on abstractions. Define interfaces in inner layers, implement them in outer layers.

### V. KEY PATTERNS

#### Repository Pattern

The Repository Pattern provides a collection-like interface for accessing domain objects, hiding the details of data storage.

##### Key Concepts

- Repository interface defined in Application layer (as a Port)
- Implementation lives in Infrastructure layer (as an Adapter)
- Encapsulates all persistence logic
- Returns domain entities, not database models
- Allows swapping storage mechanisms without changing business logic

##### In-Memory Implementations for Testing

Create in-memory implementations of repositories for fast, isolated unit tests. These implement the same interface as production repositories but store data in memory.

#### Dependency Injection

Dependency injection makes code testable and flexible by passing dependencies as parameters rather than creating them internally.

##### Key Concepts

- **Constructor Injection**: Pass dependencies when creating objects
- **Interface-based**: Depend on abstractions, not concrete types
- **Container Pattern**: Centralize dependency creation and wiring
- **Lazy Initialization**: Create expensive dependencies only when needed

#### Domain-Driven Design Patterns

##### Value Objects

Immutable objects defined by their attributes, not identity. Two value objects with the same attributes are equal.

##### Aggregates

Cluster of domain objects treated as a single unit. One entity is the "root" that controls access to the others.

##### Domain Events

Events that capture something significant that happened in the domain. Enable loose coupling between components.

#### Hexagonal Architecture (Ports and Adapters)

Hexagonal Architecture places business logic at the center with adapters handling external communication.

##### Ports (Interfaces)

- **Input/Driving Ports**: Define how external actors invoke the application
- **Output/Driven Ports**: Define what the application needs from external systems

##### Adapters (Implementations)

- **Input/Driving Adapters**: REST controllers, CLI handlers, message consumers
- **Output/Driven Adapters**: Database repositories, API clients, message publishers

Layer Responsibilities:
# Domain Layer - defines typed error hierarchy
```python
from typing import Union
from dataclasses import dataclass

@dataclass
class NotFoundError:
    entity: str
    id: str

@dataclass
class ValidationError:
    message: str

DomainError = Union[NotFoundError, ValidationError]
```

# Infrastructure Layer - exceptions caught and wrapped here
```python
from returns.result import safe

@safe
def fetch_from_database(id: str) -> Entity:
    return db.query(id)  # Exceptions auto-wrapped as Failure[Exception]


# Repository boundary - transforms infrastructure → domain errors
from returns.result import Result
from returns.pointfree import map_failure

def get_entity(id: str) -> Result[Entity, DomainError]:
    return fetch_from_database(id).map_failure(
        lambda _: NotFoundError(entity="Entity", id=id)
    )
```

# Application Layer - pure composition, no try-except
```python
from returns.pipeline import flow
from returns.pointfree import bind, map_

def process_entity(id: str) -> Result[ProcessedEntity, DomainError]:
    return flow(
        get_entity(id),
        bind(validate_entity),
        map_(transform_to_output),
    )
```

# Presentation Layer - unwrap permitted here only
```python
def handle_request(id: str) -> Response:
    result = process_entity(id)
    return result.map(to_success_response).value_or(to_error_response(result))
```
Rationale: Makes error paths explicit, enables composable error handling, enforces Clean Architecture boundaries, and prevents exception-based control flow that obscures business logic.

### VI. Test-Driven Development (TDD)

All code MUST be developed using Test-Driven Development. Write tests FIRST, then implement code to make tests pass.
TDD Cycle (MANDATORY):

RED    → Write a failing test for the new functionality
GREEN  → Write minimal code to make the test pass
REFACTOR → Clean up while keeping tests green
REPEAT → Next test case

Non-Negotiable Rules:

Tests MUST be written BEFORE implementation code (RED phase first)
Implementation MUST be minimal - only enough to pass the failing test (GREEN phase)
Refactoring MUST NOT change behavior - tests must remain green (REFACTOR phase)
One test at a time - do not batch multiple tests before implementing
Each layer MUST pass tests before implementing the next layer
Full validation: pytest MUST pass after all changes

Layer-by-Layer TDD:
| Layer | Test Type | Coverage | TDD Approach |
|-------|-----------|----------|--------------|
| Domain | Unit | 100% | Write spec/entity tests FIRST, then implement |
| Application | Acceptance | High | Write use case tests FIRST with mocked ports |
| Infrastructure | Integration | Medium | Write adapter contract tests FIRST |
| Presentation | E2E | Critical | Write controller/CLI tests FIRST |

TDD Workflow:

# 1. Domain: Write tests → Implement → Validate
```bash
pytest tests/domain/ -v              # MUST PASS ✅
```

# 2. Application: Write tests → Implement → Validate
```bash
pytest tests/application/ -v         # MUST PASS ✅
```

# 3. Infrastructure: Write tests → Implement → Validate
```bash
pytest tests/infrastructure/ -v      # MUST PASS ✅
```

# 4. Presentation: Write tests → Implement → Validate
```bash
pytest tests/presentation/ -v        # MUST PASS ✅
```

# 5. Full validation
```bash
pytest                               # Final validation ✅
```

Useful pytest Options:
```bash
pytest tests/domain/ -v              # Verbose output
pytest tests/domain/ -x              # Stop on first failure (useful in RED phase)
pytest tests/domain/ -k "test_name"  # Run specific test
pytest --cov=src --cov-report=term   # Coverage report
pytest --tb=short                    # Shorter tracebacks
```

Pytest Fixtures
Fixtures provide reusable test dependencies. Define in conftest.py for shared access across test modules.
Basic Fixtures:
# tests/conftest.py
```python
import pytest
from domain.entities import User
from domain.value_objects import Email, UserId

@pytest.fixture
def valid_user_id() -> UserId:
    return UserId("user-123")

@pytest.fixture
def valid_email() -> Email:
    return Email("test@example.com")

@pytest.fixture
def valid_user(valid_user_id, valid_email) -> User:
    """Fixtures can depend on other fixtures."""
    return User(id=valid_user_id, email=valid_email, name="Test User")
```

Factory Fixtures (for flexible test data):
# tests/conftest.py
```python
@pytest.fixture
def make_user():
    """Factory fixture for creating users with custom attributes."""
    def _make_user(
        id: str = "user-123",
        email: str = "test@example.com",
        name: str = "Test User",
    ) -> User:
        return User(id=UserId(id), email=Email(email), name=name)
    return _make_user

# tests/domain/test_user.py
def test_user_can_change_email(make_user):
    user = make_user(email="old@example.com")
    result = user.change_email(Email("new@example.com"))
    assert result.is_success()
```
Scoped Fixtures (for expensive setup):
```python
@pytest.fixture(scope="module")
def database_connection():
    """Created once per test module, shared across tests."""
    conn = create_test_database()
    yield conn
    conn.close()

@pytest.fixture(scope="function")  # Default - fresh for each test
def clean_repository(database_connection):
    """Fresh repository state for each test."""
    database_connection.truncate_all()
    return SqlUserRepository(database_connection)
```
Mocking Patterns for Port/Adapter Boundaries
Use cases depend on port interfaces (protocols), not concrete implementations. Tests mock these ports to isolate business logic.
Port Definition (Application Layer):
# src/application/ports/user_repository.py
```python
from typing import Protocol
from returns.result import Result
from domain.entities import User
from domain.errors import DomainError
from domain.value_objects import UserId

class UserRepository(Protocol):
    def find_by_id(self, user_id: UserId) -> Result[User, DomainError]: ...
    def save(self, user: User) -> Result[User, DomainError]: ...
```
Mock Implementation with unittest.mock:
# tests/application/test_get_user_use_case.py
```python
from unittest.mock import Mock
from returns.result import Success, Failure
from application.use_cases import GetUserUseCase
from domain.errors import NotFoundError

@pytest.fixture
def mock_user_repository():
    return Mock(spec=UserRepository)

@pytest.fixture
def get_user_use_case(mock_user_repository):
    return GetUserUseCase(user_repository=mock_user_repository)

def test_returns_user_when_found(get_user_use_case, mock_user_repository, valid_user):
    # Arrange
    mock_user_repository.find_by_id.return_value = Success(valid_user)

    # Act
    result = get_user_use_case.execute(valid_user.id)

    # Assert
    assert result.is_success()
    assert result.unwrap() == valid_user
    mock_user_repository.find_by_id.assert_called_once_with(valid_user.id)

def test_returns_failure_when_not_found(get_user_use_case, mock_user_repository, valid_user_id):
    # Arrange
    error = NotFoundError(entity="User", id=str(valid_user_id))
    mock_user_repository.find_by_id.return_value = Failure(error)

    # Act
    result = get_user_use_case.execute(valid_user_id)

    # Assert
    assert result.is_failure()
    assert isinstance(result.failure(), NotFoundError)
```
Fake Implementations (for complex interactions):
# tests/fakes/fake_user_repository.py
```python
from returns.result import Result, Success, Failure
from domain.errors import NotFoundError

class FakeUserRepository:
    """In-memory fake for integration-style tests."""

    def __init__(self):
        self._users: dict[str, User] = {}

    def find_by_id(self, user_id: UserId) -> Result[User, DomainError]:
        user = self._users.get(str(user_id))
        if user is None:
            return Failure(NotFoundError(entity="User", id=str(user_id)))
        return Success(user)

    def save(self, user: User) -> Result[User, DomainError]:
        self._users[str(user.id)] = user
        return Success(user)

    # Test helpers
    def seed(self, user: User) -> None:
        self._users[str(user.id)] = user
```

# tests/conftest.py
```python
@pytest.fixture
def fake_user_repository():
    return FakeUserRepository()
```
When to Use Mock vs Fake:
| Approach | Use When |
|----------|----------|
| Mock (unittest.mock) | Verifying interactions, simple return values, isolation is priority |
| Fake (in-memory impl) | Testing stateful workflows, multiple operations, behavior over interaction |

Mocking External Services (Infrastructure Tests):
# tests/infrastructure/test_http_payment_gateway.py
```python
import pytest
from unittest.mock import patch, Mock
from infrastructure.gateways import HttpPaymentGateway

@pytest.fixture
def payment_gateway():
    return HttpPaymentGateway(base_url="https://api.payments.test")

@patch("infrastructure.gateways.http_payment_gateway.requests.post")
def test_processes_payment_successfully(mock_post, payment_gateway):
    # Arrange
    mock_post.return_value = Mock(
        status_code=200,
        json=lambda: {"transaction_id": "txn-123", "status": "completed"}
    )

    # Act
    result = payment_gateway.process(amount=100, currency="USD")

    # Assert
    assert result.is_success()
    assert result.unwrap().transaction_id == "txn-123"
```
Rationale: TDD ensures code is testable by design, catches issues early, prevents over-engineering (you only write code needed to pass tests), and creates living documentation through tests.

### VII. Port/Adapter Pattern for Infrastructure

Application layer MUST define all port interfaces. Data layer MUST implement them as adapters.

**Configuration**: All runtime configuration values MUST be read from `myapp.yaml` at the repository root. Configuration loading is an infrastructure adapter that implements a configuration port. Use cases and domain logic receive configuration via constructor injection, never by reading files directly.

Non-Negotiable Rules: - Repository interfaces MUST be defined in application/ports/, NOT in data layer - Adapters MUST implement domain ports, never expose infrastructure details upward - Port definitions MUST use domain types, never infrastructure types (Infrastructure DTOs)

Data Layer Classification: - Repositories: Persistence (database, cache, file system) - Gateways: External services (MCPs, APIs)

Rationale: Allows swapping implementations, and maintains clean boundaries between domain logic and infrastructure concerns.

### VIII. DRY + YAGNI Simplicity Standards

Code MUST follow Don't Repeat Yourself (DRY) and You Aren't Gonna Need It (YAGNI) principles. Avoid over-engineering and premature abstraction.

Non-Negotiable Rules: - No Duplication: Extract shared logic only when duplicated 3+ times (Rule of Three) - No Speculative Features: Implement only what is explicitly required NOW - No Premature Abstraction: Three similar lines of code is better than one premature utility - No Unused Code: Delete dead code, unused imports, commented-out blocks immediately - No Over-Validation: Only validate at system boundaries (user input, external APIs)

YAGNI Violations to Avoid: - Adding "just in case" configurability that's not requested - Creating helpers/utilities for one-time operations - Adding feature flags for hypothetical future requirements - Designing for scenarios that can't happen in current business rules - Adding docstrings/comments to code you didn't change

DRY Application: - Check existing code BEFORE creating new files: rg "YourFeature" --type py - Check pyproject.toml BEFORE adding dependencies - Use existing domain utilities, specifications, and patterns - Prefer editing existing files over creating new ones

Rationale: Minimizes complexity, reduces maintenance burden, keeps codebase navigable, and ensures every line of code has a current, justified purpose.
Migration Constraints

Pace Control: - NEVER migrate more than 1 component per session - Each migration MUST be validated with pytest before proceeding - Incremental, validated changes only

Migration Order: 1. Domain entities (data class → regular class with behavior) 2. Value objects (primitives → NewType with validation) 3. Business logic (use cases/repos → domain specifications) 4. Port definitions (move to application layer)

Spec Cross-Check Protocol: - BEFORE implementing any feature: Cross-check against specs/ for requirements - User stories in specs/ contain Given/When/Then scenarios that MUST be implemented - If spec conflicts with request: Clarify with user before proceeding (spec is authoritative)

Current Phase: Phase 1 Foundation Layer (Domain + Application stabilization)
Quality Gates

Pre-Implementation Gates:
- [ ] Spec cross-check completed (requirements verified in specs/)
- [ ] Existing code searched (avoid duplication - DRY)
- [ ] Library dependencies checked in pyproject.toml
- [ ] Feature is explicitly requested (YAGNI compliance)
- [ ] Failing test written FIRST (TDD RED phase)

Code Quality Gates:
- [ ] No fully qualified class names (use imports with short names)
- [ ] File size ≤500 lines
- [ ] Cognitive complexity within limits:

| Threshold | Scope | Rationale |
|-----------|-------|-----------|
| **10** | Standard methods | Default maximum for most code |
| **15** | Orchestration methods | Use cases, agents, and coordinators |
| **5** | Utility/helper functions | Keep simple functions simple |

Complexity increases with: nesting depth, control flow breaks (`break`, `continue`), recursion, chained boolean operators, nested conditionals.

Reduction strategies:
- Extract methods with descriptive names
- Use guard clauses (early returns) instead of nested conditionals
- Replace complex conditionals with strategy pattern
- Extract boolean expressions into named variables

- [ ] Clean Architecture layer dependencies verified
- [ ] No speculative or "just in case" code (YAGNI)
- [ ] All tests pass (TDD GREEN phase complete)

Validation Gates (Mandatory):

Run `/validate` before committing. All gates must pass.

## Development Workflow

### Code Review Requirements

- All changes MUST be reviewed before merging
- Reviews MUST verify compliance with Constitution principles
- Reviewers MUST check for test coverage and TDD adherence

### Branch Strategy

- Feature branches from main
- Descriptive branch names: `###-feature-name` format
- Small, focused commits with clear messages

### Documentation

- Public APIs MUST be documented
- Complex logic MUST have explanatory comments
- README MUST be kept current with setup and usage instructions

## Quality Standards

### Testing Hierarchy

1. **Contract tests**: Verify public API contracts
2. **Integration tests**: Verify component interactions
3. **Unit tests**: Verify isolated logic (as needed)

### Code Quality

- Linting and formatting MUST be configured and enforced
- Type hints MUST be used (Python 3.11+)
- Error messages MUST be actionable and descriptive

## Governance

This Constitution is the authoritative source for development practices in MyApp.

### Hierarchy

1. Constitution principles override all other documentation
2. Feature specifications interpret Constitution for specific contexts
3. Implementation plans operationalize specifications

### Amendment Process

1. Propose amendment with rationale
2. Document impact on existing code and practices
3. Obtain team approval
4. Update Constitution with new version number
5. Create migration plan for affected code

### Versioning Policy

- **MAJOR**: Principle removals, redefinitions, or backward-incompatible governance changes
- **MINOR**: New principles added or existing guidance materially expanded
- **PATCH**: Clarifications, wording improvements, typo fixes

### Compliance

- All pull requests MUST pass Constitution compliance check
- Violations MUST be documented in Complexity Tracking if justified
- Unjustified violations MUST be resolved before merge

**Version**: 1.0.0 | **Ratified**: 2026-01-30 | **Last Amended**: 2026-01-30

