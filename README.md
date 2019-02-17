# Graphite

A tool to automatically create an app folder by github/tarball.

## Build

`crystal build src/graphite.cr`

## Usage

Prepare a yaml file, the syntax like the example [setting.yml](./setting.yml). There seems to be a problem with `Crystal.Dir.mkdir` that cannot use `~/` for home so change it to `/home/username/`.

`./graphite --setting setting.yml install`

Setting file is default to setting.yml so you can omit it.

Will create a folder like below in `folder` key of yaml file.

```
~/GRAPHITE/
├── app
├── bin
├── include
└── lib
```

Apps will be clone to `app/`, and then execute build commands. Then a symlink to binary, library, and include folder is made according to the patterns matches in `postinstall` field.

Then add to `.bashrc` or any config file for your shell. Here I be using `~GRAPHITE`.

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

For application that requires it self to build, like `crystal` or `yarn`, give it a link to download the tarball and show the command that should be map. If the command is not found on system PATH, then it will download the tarball (with redirect to 1, because Crystal have not implement follow redirect), extract to temp folder `/tmp/@name/` and add the found command directory to path. The path will be removed when the app is done building.

To work better, `GRAPHITE/bin` should be on PATH. Because after that if any application uses the command (in the sample file, graphite requires crystal), the command should be found.

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
