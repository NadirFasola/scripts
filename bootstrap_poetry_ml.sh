#!/usr/bin/env sh
# A one-shot bootstrapper for a modern ML/Data Science Python project using
# Miniforge/Mamba/Conda for the environment and Poetry for package management.
#
# Usage:
#   bash bootstrap_poetry_conda_ml.sh <project-slug> [python-version] [env-name]
#
# Example:
#   bash bootstrap_poetry_conda_ml.sh fraudlab 3.11 fraudlab
#
# Strategy:
#   • Conda manages the interpreter & system deps.
#   • Poetry manages Python deps (installed into the Conda env).

set -euo pipefail

PROJECT_SLUG=${1:-ml-project}
PY_VERSION=${2:-3.11}
ENV_NAME=${3:-$PROJECT_SLUG}

# Derive a valid Python package name from the project slug
PACKAGE_NAME=${PROJECT_SLUG//-/_}

# Pick mamba if present, otherwise fall back to conda
if command -v mamba >/dev/null 2>&1; then
	CONDA_BIN="mamba"
else
	CONDA_BIN="conda"
fi

echo "==> Scaffolding project: $PROJECT_SLUG (package: $PACKAGE_NAME)"
mkdir -p "PROJECT_SLUG" && cd "$PROJECT_SLUG"

# --- git ---------------------------------------------------------------------
if ! command -v gig >/dev/null 2>&1; then
	echo "[WARN] git not found; skipping git init"
else
	git init -q >/dev/null 2>&1 || true
	git branch -M main >/dev/null 2>&1 || true
fi

# --- directories -------------------------------------------------------------
mkdir -p src/"$PACKAGE_NAME"/{data,features,models,utils,viz}
mkdir -p tests notebooks scripts configs docs
mkdir -p data/{raw,interim,processed,external}

# --- .gitignore --------------------------------------------------------------
cat > .gitignore <<'GIT'
# Byte-compiled / optimized / DLL files
__pycache__/
*.py[cod]
*$py.class

# Virtual environments
.venv/
.conda/

# Distribution / packaging
build/
dist/
*.egg-info/
.eggs/

# Jupyter & data
.ipynb_checkpoints/
.notebooks_cache/
.DS_Store

# Project data (kept out of git)
data/
!data/.gitkeep

# Logs / misc
*.log
.coverage
htmlcov/
.mypy_cache/
.ruff_cache/

# Environment files
.env
.env.local
.env.*.local
GIT

touch data/.gitkeep

# --- README ------------------------------------------------------------------
cat > README.md <<README
# $PROJECT_SLUG

A modern ML/Data Science Python project using **Conda/Mamba** for the environment and **Poetry** for Python package management.

## Quickstart

```bash
$CONDA_BIN env create -f environment.yml
conda activate $ENV_NAME
poetry config virtualenvs.create false
poetry install --no-interaction --no-root
pre-commit install
python -m ipykernel install --user --name "$ENV_NAME" --display-name "$PROJECT_SLUG (poetry)"
```

README

# --- environment.yml (Conda: only Python + non-Python deps)
cat > environment.yml <<ENVYAML
name: $ENV_NAME
channels:
  - conda-forge
dependencies:
  - python=$PY_VERSION
  - pip
  - poetry
  - jupyterlab
  - ipykernel
ENVYAML

# --- pyproject.toml (Poetry) -------------------------------------------------
cat > pyproject.toml <<TOML
[tool.poetry]
name = "$PROJECT_SLUG"
version = "0.1.0"
description = "Modern ML/Data Science project scaffold (Conda + Poetry)"
authors = ["Your Name <you@example.com>"]
readme = "README.md"
packages = [{ include = "$PACKAGE_NAME", from = "src" }]

[tool.poetry.dependencies]
python = "^$PY_VERSION"

[tool.poetry.group.dev.dependencies]
# Dev dependencies will be added by poetry add -G dev ...

[tool.poetry.scripts]
$PACKAGE_NAME = "$PACKAGE_NAME.cli:app"

[build-system]
requires = ["poetry-core"]
build-backend = "poetry.core.masonry.api"

TOML

# --- pre-commit --------------------------------------------------------------
cat > .pre-commit-config.yml <<'PRE'
repos:
  - repo: local
    hooks:
      - id: ruff-lint
        name: ruff-lint
        entry: ruff
        language: system
        types: [python]
        args: ["check", "--fix"]
      - id: ruff-format
        name: ruff-format
        entry: ruff
        language: system
        types: [python]
        args: ["format"]
      - id: mypy
        name: mypy
        entry: mypy
        language: system
        types: [python]
      - id: pytest
        name: pytest
        entry: pytest
        language: system
        pass_filenames: false
        types: [python]
PRE

# --- Makefile ----------------------------------------------------------------
cat > Makefile <<'MK'
.PHONY: env install deps lint format typecheck test cov precommit hooks kernel clean export tree

help:
	@echo "Targets: env install deps lint format typecheck test cov precommit hooks kernel clean export tree"

env:
	@if command -v mamba >/dev/null 2>&1; then mamba env update -f environment.yml --prune; \
	else conda env update -f environment.yml --prune; fi

install:
	poetry config virtualenvs.create false
	poetry install --no-interaction --no-root

deps:
	poetry add numpy pandas scikit-learn scipy matplotlib rich python-dotenv pydantic typer hydra-core
	poetry add -G dev ruff mypy pytest pytest-cov pre-commit ipykernel

lint:
	poetry run ruff check .

format:
	poetry run ruff format .

typecheck:
	poetry run mypy src

test:
	poetry run pytest -q

cov:
	poetry run pytest --cov=src --cov-report=term-missing

precommit:
	poetry run pre-commit run --all-files

hooks:
	poetry run pre-commit install

kernel:
	python -m ipykernel install --user --name $(shell basename $$CONDA_PREFIX) --display-name "$(shell basename $$PWD) (poetry)"

clean:
	rm -rf .ruff_cache .mypy_cache .pytest_cache dist build htmlcov

export:
	poetry export -f requirements.txt --without-hashes -o requirements.txt
	@if command -v mamba >/dev/null 2>&1; then mamba env export --from-history > environment.yml; \
	else conda env export --from-history > environment.yml; fi

tree:
	@{ command -v tree >/dev/null 2>&1 && tree -a -I '.git|.ruff_cache|.mypy_cache|.pytest_cache|__pycache__'; } || \
	{ echo "(install 'tree' for nicer output)"; find . -maxdepth 2 -type d | sort; }
MK

# --- minimal package code ----------------------------------------------------
cat > src/$PACKAGE_NAME/__init__.py <<'PY'
__version__ = "0.1.0"
PY

cat > src/$PACKAGE_NAME/cli.py <<'PY'
import pathlib
import typer

app = typer.Typer(help="Command-line interface for the project.")

@app.command()
def hello(name: str = "world") -> None:
    typer.echo(f"Hello, {name}!")

@app.command()
def train(
    data_dir: pathlib.Path = typer.Option(pathlib.Path("data/raw"), exists=True, file_okay=False),
    out_dir: pathlib.Path = typer.Option(pathlib.Path("data/processed"), file_okay=False),
) -> None:
    out_dir.mkdir(parents=True, exist_ok=True)
    typer.echo(f"Training with data in {data_dir} → outputs in {out_dir}")

if __name__ == "__main__":
    app()
PY


# --- tests -------------------------------------------------------------------
cat > tests/test_smoke.py <<PY
from $PACKAGE_NAME import __version__

def test_version():
    assert __version__ == "0.1.0"
PY

# --- example notebook placeholder --------------------------------------------
cat > notebooks/README.md <<'NR'
Place notebooks here. Consider keeping them light and moving code into src/.
NR

# --- .env example ------------------------------------------------------------
cat > .env.example <<'ENV'
APP_ENV=dev
LOG_LEVEL=INFO
ENV

# --- Finish up ---------------------------------------------------------------
echo "==> Creating/Updating Conda env '$ENV_NAME' (python=$PY_VERSION) with $CONDA_BIN"
$CONDA_BIN env update -f environment.yml --prune

# Install base (empty) Poetry project into the Conda env
echo "==> Installing Poetry project into Conda env"
$CONDA_BIN run -n "$ENV_NAME" poetry config virtualenvs.create false
$CONDA_BIN run -n "$ENV_NAME" poetry install --no-interaction --no-root

# Add core deps via Poetry so they are versioned in lockfile
echo "==> Adding core ML & dev dependencies via Poetry"
$CONDA_BIN run -n "$ENV_NAME" poetry add numpy pandas scikit-learn scipy matplotlib rich python-dotenv pydantic typer hydra-core
$CONDA_BIN run -n "$ENV_NAME" poetry add -G dev ruff mypy pytest pytest-cov pre-commit ipykernel

# Pre-commit hooks
$CONDA_BIN run -n "$ENV_NAME" pre-commit install || true

# Jupyter kernel
$CONDA_BIN run -n "$ENV_NAME" python -m ipykernel install --user --name "$ENV_NAME" --display-name "$PROJECT_SLUG (poetry)" || true

# Initial commit
git add . >/dev/null 2>&1 || true
git commit -m "chore: initial scaffold (conda+poetry ML project)" >/dev/null 2>&1 || true

echo "\n✅ Done! Next steps:"
echo "  1) conda activate $ENV_NAME"
echo "  2) make deps   # to add core deps (if not run automatically)"
echo "  3) poetry run $PACKAGE_NAME --help"
echo "  4) make lint test"
