# Changelog

All notable changes to this project will be documented in this file.

Migration notes are available in the [migration guide](<REPO>/blob/main/MIGRATION.md).

## [0.2.0] - 2025-02-28

### 🚀 Features

- *(config)* [**breaking**] New 'precision' config to limit similarity decimal digits (default=3)
having a fixed precision prevents subsequent runs of the plugin to
    generate different similarity values with no actual difference, yet
    pointlessly editing previously generated files in _data/related_posts dir.
    This may come annoying for setups that looks at those files and require
    them to be committed automatically (e.g. CD pipelines)
- Dry-run support
- *(config)* [**breaking**] Specify db table and stored procedure names
- *(config)* [**breaking**] Support to run in different environments

### 🐛 Bug Fixes

- Avoid mistekenly calling update function every time
- Quiet and debug options not working

### 🚜 Refactor

- Improved initial output info

### ⚙️ Miscellaneous Tasks

- Badges in readme
- Update readme with Jekyll integration instructions
- Added option description to readme
- Updated git-cliff config and rakefile fixes

## [0.1.0] - 2025-02-15

### 🚀 Features

- Project setup
- Supabase SQL scripts
- First full implementation

### ⚙️ Miscellaneous Tasks

- Readme update
- Rakefile
- Update CHANGELOG.md
- Release workflow

