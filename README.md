<h1> ConvFT - File and Text Converter </h1>

<h2>Table of Contents</h2>

- [Introduction](#introduction)
- [Repository](#repository)
- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
- [How It Works](#how-it-works)
- [Notes](#notes)
- [Contributing](#contributing)
- [License](#license)

---

## Introduction

ConvFT is a simple yet powerful bash script that allows you to convert between files and a single text file representation. It's perfect for backing up file structures, sharing multiple files as a single text file, or reconstructing files from a text representation.

## Repository

https://github.com/Mik-TF/convft

## Features

- Convert multiple files (including directory structure) into a single text file
- Reconstruct files and directories from the text file representation
- Easy to install and use
- Lightweight and portable

## Installation

You can install ConvFT directly from this repository:

```bash
git clone https://github.com/Mik-TF/convft.git
cd convft
sudo bash convft.sh install
```

This will install the script to `/usr/local/bin/convft`, making it available system-wide.

## Usage

After installation, you can use ConvFT with the following commands:

1. To convert files to text:
   ```
   convft ft
   ```
   This will create a file named `all_files_text.txt` in the current directory, containing the content of all files in the current directory and its subdirectories.

2. To convert text back to files:
   ```
   convft tf
   ```
   This will read the `all_files_text.txt` file in the current directory and reconstruct the original files and directory structure.

3. To uninstall ConvFT:
   ```
   sudo convft uninstall
   ```
   This will remove ConvFT from your system.

## How It Works

- The `ft` (file-to-text) option recursively scans the current directory and its subdirectories, writing the content of each file to `all_files_text.txt` along with filename information.
- The `tf` (text-to-file) option reads `all_files_text.txt` and recreates the original file structure and content.

## Notes

- Be cautious when using the `tf` option, as it will overwrite existing files with the same names.
- The script skips processing itself and the output file to avoid recursive issues.

## Contributing

Contributions, issues, and feature requests are welcome! Feel free to check the [issues page](https://github.com/Mik-TF/convft/issues).

## License

This project is licensed under the Apache License, Version 2.0. See the [LICENSE](LICENSE) file for details.
