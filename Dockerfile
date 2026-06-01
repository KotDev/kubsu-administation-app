FROM python:3.12-slim AS builder

WORKDIR /build
RUN python -m venv /venv
COPY pyproject.toml .
RUN /venv/bin/pip install --no-cache-dir --timeout 120 .


FROM python:3.12-slim AS production

COPY --from=builder /venv /venv
ENV PATH="/venv/bin:$PATH"

WORKDIR /app
COPY src/ ./src/

ENV APP_PORT=8000
EXPOSE ${APP_PORT}

CMD ["sh", "-c", "uvicorn src.main:app --host 0.0.0.0 --port ${APP_PORT}"]


FROM production AS test

COPY pyproject.toml .
RUN pip install --no-cache-dir --timeout 120 ".[test]"
COPY tests/ ./tests/

CMD ["pytest", "tests", "-v"]
