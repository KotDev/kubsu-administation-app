# Stage 1: builder — installs dependencies into an isolated venv
FROM python:3.12-slim AS builder

WORKDIR /build
RUN python -m venv /venv
COPY pyproject.toml .
RUN /venv/bin/pip install --no-cache-dir .


# Stage 2: production — minimal runtime image
FROM python:3.12-slim AS production

COPY --from=builder /venv /venv
ENV PATH="/venv/bin:$PATH"

WORKDIR /app
COPY src/ ./src/

ENV APP_PORT=8000
EXPOSE ${APP_PORT}

CMD ["sh", "-c", "uvicorn src.main:app --host 0.0.0.0 --port ${APP_PORT}"]


# Stage 3: test — extends production with test dependencies
FROM production AS test

COPY pyproject.toml .
RUN pip install --no-cache-dir ".[test]"
COPY tests/ ./tests/

CMD ["pytest", "tests", "-v"]
