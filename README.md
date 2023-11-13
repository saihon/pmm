[fzf-repo]:https://github.com/junegunn/fzf
[fzf-installation]:https://github.com/junegunn/fzf#installation

[jq-repo]:https://github.com/jqlang/jq
[jq-installation]:https://github.com/jqlang/jq#installation

# pmm

pmm is a command-line tool for managing package managers.

# Demo

![demo](https://github.com/saihon/pmm/blob/media/pmm-demo.gif)

# Installation

This command uses [fzf][fzf-repo] and [jq][jq-repo]. [fzf][fzf-repo] is a command-line fuzzy finder, used by pmm interactive selection. It can be installed from [here][fzf-installation]. [jq][jq-repo] is a command-line JSON processor, used by pmm parse JSON. It can be installed from [here][jq-installation].

<br/>


* Download
  ```
  git clone https://github.com/saihon/pmm.git
  ```
  ```
  cd pmm
  ```
  
* Build & install (Default location /usr/local/bin)
  ```
  make && make install
  ```
  Change install location
  ```
  make && make install PREFIX=~/.local/bin
  ```

OR

* Download
  ```
  wget https://raw.githubusercontent.com/saihon/pmm/master/pmm.sh
  ```

* Build and install
  ```
  cp pmm.sh pmm && chmod 755 pmm && sudo mv pmm /usr/local/bin
  ```

<br/>

# Usage

<br/>

* Path of the JSON file to be created.
  + Linux:
    `$XDG_DATA_HOME/pmm/pmm.json` or `$HOME/.local/share/pmm/pmm.json`
  + MacOS:
    `$HOME/Library/Application/pmm/pmm.json`
  + Environment variable:
    Can set the JSON file path by writing the following in `~/.bashrc`
    `export PMM_JSON_FILE_PATH=~/path/to/dir/data.json`
    And reloading.
    `source ~/.bashrc`

<br/>

* Add packages.
  ```
  $ pmm add -n npm -c 'npm install -D' typescript webpack eslint...
  ```

  If you have added the it name already, can select it interactively next time
  ```
  $ pmm add typescript webpack eslint...
  ```

  Specify the JSON file to add
  ```
  $ pmm add -j=./data.json typescript webpack eslint...
  ```
 
<br/>

* Edit JSON file (By default uses the value of $EDITOR) 
  ```
  $ pmm edit
  ```

  Or specify the editor to use.
  ```
  $ pmm edit -c code
  ```

  Specify the JSON file to edit.
  ```
  $ pmm edit -j=./data.json
  ```
 
<br/>

* Install packages
  ```
  $ pmm install
  ```

  Specify a command to be used only this time.
  ```
  $ pmm install -c='npm install -g'
  ```

  Check command details to run before the installation.
  ```
  $ pmm install -i
  ```

  Add packages and run the installation.
  ```
  $ pmm install -a webpack typescript
  ```

  Add commands and run the installation.
  ```
  $ pmm install -a -c='npm install -g'
  ```

  Install all packages belonging to the selected name.
  ```
  $ pmm install --all
  ```

  Specify the JSON file to use.
  ```
  $ pmm install -j=./data.json
  ```
 