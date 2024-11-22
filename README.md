# jupyter_ascending.kak

To install, put `rc/jupyter_ascending.kak` into your autoload.

You'll probably find something like this useful, too:

```kakscript
hook global BufCreate .*\.sync\.py$ %{
  # 'e' stands for 'eval'?
  map buffer user e '<esc>: enter-user-mode jupyter-ascending<ret>' -docstring 'jupyter_ascending'
}
```

## Dev setup

```sh
just setup # or setup-nb to skip `pip install` if using the flake.
```

Readme: https://github.com/imbue-ai/jupyter_ascending/blob/main/README.md
