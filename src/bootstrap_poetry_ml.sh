#!/usr/bin/env bash
# a one-shot bootstrapper for a modern ml/data science python project using
# miniforge/mamba/conda for the environment and poetry for package management.
#
# usage:
#   bash bootstrap_poetry_conda_ml.sh <project-slug> [python-version] [env-name]
#
# example:
#   bash bootstrap_poetry_conda_ml.sh fraudlab 3.11 fraudlab
#
# strategy:
#   • conda manages the interpreter & system deps.
#   • poetry manages python deps (installed into the conda env).

set -euo pipefail

project_slug=${1:-ml-project}
py_version=${2:-3.11}
env_name=${3:-$project_slug}

# derive a valid python package name from the project slug
package_name=${project_slug//-/_}

# kernel-safe env name (underscores only)
env_name_safe=${env_name//-/_}

# pick mamba if present, otherwise fall back to conda
if command -v mamba >/dev/null 2>&1; then
	conda_bin="mamba"
else
	conda_bin="conda"
fi

echo "==> scaffolding project: $project_slug (package: $package_name)"
mkdir -p "$project_slug" && cd "$project_slug"

# --- git ---------------------------------------------------------------------
if ! command -v git >/dev/null 2>&1; then
	echo "[warn] git not found; skipping git init"
else
	git init -q >/dev/null 2>&1 || true
	git branch -m main >/dev/null 2>&1 || true
fi

# --- directories -------------------------------------------------------------
mkdir -p src/"$package_name"/{data,features,models,utils,viz}
mkdir -p tests notebooks scripts configs docs
mkdir -p data/{raw,interim,processed,external}

# helper to escape replacement strings for sed
_esc() { printf '%s' "$1" | sed -e 's/[\/&]/\\&/g'; }

# --- .gitignore --------------------------------------------------------------
cat > .gitignore <<'git'
__pycache__/
*.py[cod]
*$py.class

.venv/
.conda/

build/
dist/
*.egg-info/
.eggs/

.ipynb_checkpoints/
.notebooks_cache/
.DS_Store

data/
!data/.gitkeep

*.log
.coverage
htmlcov/
.mypy_cache/
.ruff_cache/

.env
.env.local
.env.*.local
git

touch data/.gitkeep

# --- readme ------------------------------------------------------------------
cat > readme.md <<'readme'
# $project_slug

a modern ml/data science python project using **conda/mamba** for the environment and **poetry** for python package management.

## quickstart

```bash
$conda_bin env create -f environment.yml
conda activate $env_name
poetry config virtualenvs.create false
poetry install --no-interaction --no-root
pre-commit install
python -m ipykernel install --user --name "$env_name_safe" --display-name "$project_slug (poetry)"
```
readme

# substitute shell variables in readme.md (literal $... in file -> replace)
sed -i "s/\$project_slug/$( _esc "$project_slug" )/g" readme.md
sed -i "s/\$conda_bin/$( _esc "$conda_bin" )/g" readme.md
sed -i "s/\$env_name/$( _esc "$env_name" )/g" readme.md
# replace quoted env_name_safe occurrence (with quotes in file) and unquoted ones
sed -i "s/\$env_name_safe/$( _esc "$env_name_safe" )/g" readme.md

# --- environment.yml (conda: only python + non-python deps)
cat > environment.yml <<'envyaml'
name: $env_name
channels:
  - conda-forge
  - defaults
dependencies:
  - python=$py_version
  - pip
  - poetry
  - jupyterlab
  - ipykernel
envyaml

# substitute variables in environment.yml
sed -i "s/\$env_name/$( _esc "$env_name" )/g" environment.yml
sed -i "s/\$py_version/$( _esc "$py_version" )/g" environment.yml

# --- pyproject.toml (poetry) -------------------------------------------------
cat > pyproject.toml <<'toml'
[tool.poetry]
name = "$project_slug"
version = "0.1.0"
description = "modern ml/data science project scaffold (conda + poetry)"
authors = ["your name <you@example.com>"]
readme = "readme.md"
packages = [{ include = "$package_name", from = "src" }]

[tool.poetry.dependencies]
python = ">=${py_version},<${py_version%.*}$((${py_version##*.}+1))"
numpy = "*"
pandas = "*"
scikit-learn = "*"
scipy = "*"
matplotlib = "*"
rich = "*"
python-dotenv = "*"
pydantic = "*"
typer = "*"
hydra-core = "*"

[tool.poetry.group.dev.dependencies]
ruff = "*"
mypy = "*"
pytest = "*"
pytest-cov = "*"
pre-commit = "*"
ipykernel = "*"

[tool.poetry.scripts]
$package_name = "$package_name.cli:app"

[build-system]
requires = ["poetry-core"]
build-backend = "poetry.core.masonry.api"
toml

# Now substitute simple variables in pyproject.toml
sed -i "s/\$project_slug/$( _esc "$project_slug" )/g" pyproject.toml
sed -i "s/\$package_name/$( _esc "$package_name" )/g" pyproject.toml
sed -i "s/\$py_version/$( _esc "$py_version" )/g" pyproject.toml

# Replace the complex python spec expression with an evaluated form
py_major=${py_version%.*}
py_minor=${py_version##*.}
evaluated_python_spec=">=${py_version},<${py_major}.$((py_minor+1))"
# replace the entire right-hand side of the python = "..." line
sed -i -E "s/^(python = \\\").*(\\\")/\\1$( _esc "$evaluated_python_spec" )\\2/" pyproject.toml

# --- pre-commit --------------------------------------------------------------
cat > .pre-commit-config.yml <<'pre'
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
pre

# --- makefile ----------------------------------------------------------------
cat > makefile <<'mk'
.phony: env install deps lint format typecheck test cov precommit hooks kernel clean export tree

help:
	@echo "targets: env install deps lint format typecheck test cov precommit hooks kernel clean export tree"

env:
	@if command -v mamba >/dev/null 2>&1; then mamba env update -f environment.yml --prune; \
	else conda env update -f environment.yml --prune; fi

install:
	poetry config virtualenvs.create false
	poetry install --no-interaction --no-root

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
	python -m ipykernel install --user --name $(shell basename $$conda_prefix | tr '-' '_') --display-name "$(shell basename $$pwd) (poetry)"

clean:
	rm -rf .ruff_cache .mypy_cache .pytest_cache dist build htmlcov

export:
	poetry export -f requirements.txt --without-hashes -o requirements.txt
	@if command -v mamba >/dev/null 2>&1; then mamba env export --from-history > environment.yml; \
	else conda env export --from-history > environment.yml; fi

tree:
	@{ command -v tree >/dev/null 2>&1 && tree -a -i '.git|.ruff_cache|.mypy_cache|.pytest_cache|__pycache__'; } || \
	{ echo "(install 'tree' for nicer output)"; find . -maxdepth 2 -type d | sort; }
mk

# --- minimal package code ----------------------------------------------------
cat > src/$package_name/__init__.py <<'py'
__version__ = "0.1.0"
py

cat > src/$package_name/cli.py <<'py'
import pathlib
import typer

app = typer.Typer(help="command-line interface for the project.")

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
py

# --- tests -------------------------------------------------------------------
cat > tests/test_smoke.py <<'py'
from $package_name import __version__

def test_version():
    assert __version__ == "0.1.0"
py

# substitute package name in tests
sed -i "s/\$package_name/$( _esc "$package_name" )/g" tests/test_smoke.py

# --- example notebook placeholder --------------------------------------------
cat > notebooks/readme.md <<'nr'
place notebooks here. consider keeping them light and moving code into src/.
nr

# --- .env example ------------------------------------------------------------
cat > .env.example <<'env'
app_env=dev
log_level=info
env

# --- finish up ---------------------------------------------------------------
echo "==> creating/updating conda env '$env_name' (python=$py_version) with $conda_bin"

if ! $conda_bin env list | awk '{print $1}' | grep -qx "$env_name"; then
    echo "==> creating new conda env: $env_name"
    $conda_bin env create -f environment.yml
else
    echo "==> updating existing conda env: $env_name"
    $conda_bin env update -f environment.yml --prune
fi

echo "==> installing poetry project into conda env"
$conda_bin run -n "$env_name" python -m poetry config virtualenvs.create false
$conda_bin run -n "$env_name" python -m poetry install --no-interaction --no-root

echo "==> installing pre-commit hooks"
$conda_bin run -n "$env_name" python -m poetry run pre-commit install || true

echo "==> registering jupyter kernel ($env_name_safe)"
$conda_bin run -n "$env_name" python -m ipykernel install --user --name "$env_name_safe" --display-name "$project_slug (poetry)" || true

# initial commit
git add . >/dev/null 2>&1 || true
git commit -m "chore: initial scaffold (conda+poetry ml project)" >/dev/null 2>&1 || true

echo
echo "✅ done! next steps:"
echo " 1) conda activate $env_name"
echo " 2) poetry run $package_name --help"
echo " 3) make lint test"
