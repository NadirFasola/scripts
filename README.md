# 🛠️ My Scripts

A personal collection of utilities and project bootstrap scripts.  
I keep this folder in my `$PATH` so I can use these commands anywhere.

## Features

- **Project scaffolding**  
  - `bootstrap_poetry_ml.sh`: scaffold a modern ML/Data Science project using Conda/Mamba + Poetry + pre-commit tooling.

- **Extendable toolbox**  
  - Add other scripts as needed (e.g., data helpers, cluster submission templates, git shortcuts).

## Installation

Clone the repo and add it to your `PATH`:

```bash
git clone git@github.com:<your-username>/scripts.git ~/scripts
echo 'export PATH=\"$HOME/scripts:$PATH\"' >> ~/.bashrc
source ~/.bashrc
```

Make sure scripts are exectuable
```bash
chmod +x ~/scripts/*.sh
```

## Usage

- [bootstrap_poetry_ml.sh](#bootstrap_poetry_mlsh)

### bootstrap_poetry_ml.sh

From anywere:

```bash
# Scaffold a new ML project
bootstrap_poetry_ml.sh <project_slug> [python-version] [env-name]
```

Then:

```bash
cd <project-slug>
conda activate <env-name>
make deps
```

## Contributing/Modifying

This is my personal repo: I regularly tweak scripts here.

If you modify a script, commit the change:

```bash
git add <script>
git commit -m "feat: update <script> script"
git push
```

## License

This repository is licensed under the [MIT License](LICENSE).

You are free to use, modify, and distribute these scripts with proper attribution.
