# syntax=docker/dockerfile:1
FROM python:3.12-slim

# Prevents Python from writing .pyc files and uses unbuffered stdout/stderr
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# No extra OS packages required; rely on prebuilt wheels

# Set workdir
WORKDIR /app

# Copy project files
COPY pyproject.toml README.md ./
COPY src ./src

# Install package
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir .

# Create a non-root user
RUN useradd -ms /bin/bash appuser
USER appuser

# Default entrypoint to CLI
ENTRYPOINT ["titanic-pipeline"]
# Show help by default
CMD ["--help"]
