# CompetiBest.nvim

<div align="center">

![Neovim](https://img.shields.io/badge/NeoVim-0.5+-%2357A143.svg?&style=for-the-badge&logo=neovim)
![Lua](https://img.shields.io/badge/Lua-%232C2D72.svg?style=for-the-badge&logo=lua)
![License](https://img.shields.io/github/license/MihneaTs1/competitest.nvim?style=for-the-badge&logo=gnu)

## Competitive Programming with Neovim made Easy

<!-- ![competibest_old](https://user-images.githubusercontent.com/88047141/147982101-2576e960-372c-4dec-b65e-97191c23a57d.png) -->
![CompetiBest_popup_ui](https://user-images.githubusercontent.com/88047141/149839002-280069e5-0c71-4aec-8e39-4443a1c44f5c.png)
*CompetiBest's popup UI*

![CompetiBest_split_ui](https://user-images.githubusercontent.com/88047141/183751179-e07e2a4d-e2eb-468b-ba34-bb737cba4557.png)
*CompetiBest's split UI*

</div>

## Competitive Programming with Neovim Made Easy

**CompetiBest.nvim** is a powerful Neovim plugin designed for competitive programmers. It automates and simplifies the process of managing, running, and debugging your code against multiple testcases. Whether you are competing in a contest or practicing locally, CompetiBest.nvim streamlines your workflow by handling common tasks such as compiling, executing, and verifying your solutions—all within an interactive user interface.

### Overview

- **Testcase Management:**  
  Create, edit, delete, and convert testcases seamlessly. Testcases can be stored either as multiple text files or a single msgpack encoded file, according to your preference or project needs.

- **Automated Compilation & Execution:**  
  The plugin supports several popular programming languages (C, C++, Rust, Java, Python) out of the box. It automatically compiles and runs your code across all defined testcases, saving you time during contests.

- **Interactive UI:**  
  View detailed execution data in both popup and split window interfaces. Easily inspect testcases, standard input/output, errors, and even view diffs between actual and expected outputs with customizable keybindings.

- **Competitive Companion Integration:**  
  Download problems, testcases, and contest data directly from competitive programming platforms via the [competitive-companion](https://github.com/jmerle/competitive-companion) extension. The plugin even supports customizable folder structures and file templates for received problems.

- **Fully Configurable:**  
  With a rich set of configuration options, you can tailor every aspect of the plugin—from folder structure and file naming conventions to UI layout, keybindings, and language-specific compile/run commands. Local configuration allows you to set different options per project or contest.

---

## Features

- **Multi-language Support:**  
  Works out of the box with C, C++, Rust, Java, and Python. Other languages can be configured easily.

- **Flexible File & Folder Structure:**  
  No strict naming rules; customize the storage for source files, testcases, problems, and contests.

- **Testcase Editing & Viewing:**  
  Quickly add, edit, or delete testcases with a dedicated editor. View detailed outputs (stdout, stderr) and diff views for debugging.

- **Parallel & Controlled Execution:**  
  Run multiple testcases simultaneously. Re-run specific testcases or kill running processes as needed.

- **Interactive & Adaptive UI:**  
  Choose between popup or split interfaces that automatically adjust when you resize Neovim. Customize layout and integrate with statuslines/winbars.

- **Download & Receive Problems:**  
  Automatically fetch problems and contest data from competitive programming websites with a single command.

- **Customizable Templates & Highlights:**  
  Configure source code templates for downloaded problems and customize UI highlight groups to match your theme.

---

## Installation

**NOTE:** This plugin requires Neovim ≥ 0.5

Install with **vim-plug**:
```vim
Plug 'MunifTanjim/nui.nvim'        " dependency
Plug 'MihneaTs1/competibest.nvim'
```

Install with **packer.nvim**:
```lua
use {
	'MihneaTs1/competibest.nvim',
	requires = 'MunifTanjim/nui.nvim',
	config = function() require('competibest').setup() end
}
```

Install with **lazy.nvim**:
```lua
{
	'MihneaTs1/competibest.nvim',
	dependencies = 'MunifTanjim/nui.nvim',
	config = function() require('competibest').setup() end,
}
```

*If you are using another package manager, make sure that [`nui.nvim`](https://github.com/MunifTanjim/nui.nvim) is installed as it is required by CompetiBest.nvim.*

---

## Usage

To load the plugin with default settings:
```lua
require('competibest').setup()
```
Or, to customize settings:
```lua
require('competibest').setup {
	-- Your custom configuration options here
}
```
For a complete list of options, please see the [Configuration](#configuration) section below.

### Quick Start

1. **Prepare Your Source:**  
   Ensure your solution reads from `stdin` and outputs to `stdout`.

2. **Manage Testcases:**  
   Use commands like `:Competibest add_testcase`, `:Competibest edit_testcase`, or `:Competibest delete_testcase` to manage testcases. You can store testcases in one file or multiple files as per your setup.

3. **Run & Debug:**  
   Execute `:Competibest run` to compile and test your solution against all testcases. View detailed outputs, rerun individual testcases with `R`, or use `<C-r>` to run all testcases again.

4. **Download Problems:**  
   Install the [competitive-companion](https://github.com/jmerle/competitive-companion) browser extension, then use `:Competibest receive` to automatically download testcases and source files for new problems.

---

## Contributing

If you have suggestions or encounter any issues, please open a new issue or submit a pull request. Contributions are welcome!

---

## License

GNU Lesser General Public License version 3 (LGPL v3) or, at your option, any later version.

© 2021-2023 [MihneaTs1](https://github.com/MihneaTs1)

CompetiBest.nvim is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation.

For full license details, see [GNU LGPL v3](https://www.gnu.org/licenses/).
