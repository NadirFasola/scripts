# 🛠️ My Scripts

A personal collection of utilities and project bootstrap scripts.  
I keep this folder in my `$PATH` so I can use these commands anywhere.

## Features

- **Project scaffolding:**  
  - `src/bootstrap_poetry_ml.sh`: scaffold a modern ML/Data Science project using Conda/Mamba + Poetry + pre-commit tooling.

- **Install script:** `install.sh`: install or uninstall scripts from `src/` to `$XDG_DATA_HOME/scripts` as symlinks, automatically managing your PATH. Supports individual script installation, removal, and full cleanup.

- **Extendable toolbox:**
  - Add other scripts as needed (e.g., data helpers, cluster submission templates, git shortcuts).

## Installation

Clone the repo, then use the `install.sh` script to link scripts from the `src/` folder into your local scripts directory:

```bash
git clone git@github.com:NadirFasola/scripts.git <download_folder>/scripts
cd <download_folder>/scripts
chmod +x ./install.sh
```
From here, you can install scripts from the `src/` folder:

```bash
./install.sh <script>
```

The `install.sh` script manages your PATH automatically by adding `$XDG_DATA_HOME/scripts` if needed.

## Usage

After installing scripts via `install.sh`, they are available globally in your `PATH`, so you can call them from anywhere without specifying the full path.

- [Installing](#Installingscripts)
- [Uninstalling](#Uninstallingscripts)
- [bootstrap_poetry_ml.sh](#bootstrap_poetry_mlsh)

### Installing scripts

To install a specific script from the `src/` folder:

```bash
./install.sh <script>
```

To install all scripts at once:

```bash
./install.sh *
```

### Uninstalling scripts

Remove a single script:

```bash
./install.sh -u <script>
```

Remove all installed scripts and clean up the `$XDG_DATA_HOME/scripts` folder from `PATH`:

```bash
./install.sh -U
```

### bootstrap_poetry_ml.sh

After installing via install.sh, you can use it directly:

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

If you modify a script, commit the change according to the [Conventional Commits specification](https://www.conventionalcommits.org/en/v1.0.0/):

```bash
git add <script>
git commit -m "feat: update <script> script"
git push
```

## License

This repository is licensed under the [MIT License](LICENSE).

You are free to use, modify, and distribute these scripts with proper attribution.
