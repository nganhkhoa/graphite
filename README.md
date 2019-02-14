# Graphite

A tool to automatically create an app folder by github/tarball.

## Build

`crystal build src/graphite.cr`

## Usage

Prepare a yaml file, the syntax like the example [setting.yml](./setting.yml).

`./graphite --setting setting.yml install`

Will create a folder like below in `folder` key of yaml file, default to `~/GRAPHITE`.

```
~/GRAPHITE/
├── app
├── bin
├── include
└── lib
```

Apps will be clone to `app/`, and the execute build commands. Then will make symlink to binary, library, and include folder.

Then add to `.bashrc` or any config file for your shell.

```bash
# path file
export PATH=~/GRAPHITE/bin:$PATH

# ld lib files
export LD_LIBRARY_PATH=~/GRAPHITE/lib:$LD_LIBRARY_PATH

# gcc and g++ header files
export LIBRARY_PATH=~/GRAPHITE/include:$LIBRARY_PATH
```

Not usable with tools requires setting in shell (pyenv, nvm, ...). This could be solve by adding those in a config file and source it.

```bash
# ~/.bashrc
source ~/GRAPHITE/conf.bash

# ~/GRAPHITE/conf.bash
if command -v pyenv 1>/dev/null 2>&1; then
    eval "$(pyenv init -)"
    eval "$(pyenv virtualenv-init -)"
fi
```

## Development

TODO: Write development instructions here

## Contributing

1. Fork it (<https://github.com/your-github-user/graphite/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Nguyễn Anh Khoa](https://github.com/your-github-user) - creator and maintainer