# Graphite

A tool to automatically create an app folder by github/tarball.

## Build

`crystal build src/graphite.cr`

## Usage

Prepare a yaml file, the syntax like the example [setting.yml](./setting.yml) and place it in an empty folder. Run `graphite install`, it will create the bellowing file structure, clone the app in `setting.yml`, build the app with the given commands, and make a symlink (also predefined in setting.yml).

```
GRAPHITE/
├── app
├── bin
├── include
└── lib
```

The general command is `graphite [options] [apps]`.

After that, just modify your path to contains GRAPHITE, like below.

```bash
# path file
export PATH=~/GRAPHITE/bin:$PATH

# ld lib files
export LD_LIBRARY_PATH=~/GRAPHITE/lib:$LD_LIBRARY_PATH

# gcc and g++ header files
export LIBRARY_PATH=~/GRAPHITE/include:$LIBRARY_PATH
```

Not usable with tools requires setting in shell (pyenv, nvm, ...). This could be solve by adding those in a config file and source it. WORK IS TO BE DONE.

```bash
# ~/.bashrc
source ~/GRAPHITE/conf.bash

# ~/GRAPHITE/conf.bash
if command -v pyenv 1>/dev/null 2>&1; then
    eval "$(pyenv init -)"
    eval "$(pyenv virtualenv-init -)"
fi
```

For application that requires itself to build, (crystal, yarn), give it a tar.gz file download link with the command path after extraction. It will use the binary downloaded to build, for exactly, it add the folder to path.

For application that requires others to build first, this will be solved by making a topology before running the main worker. WORK IS TO BE DONE.

## Development

TODO: Write development instructions here

## Contributing

1. Fork it (<https://github.com/your-github-user/graphite/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Nguyễn Anh Khoa](https://github.com/nganhkhoa) - creator and maintainer
