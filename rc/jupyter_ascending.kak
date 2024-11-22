provide-module -override jupyter-ascending %{
  declare-option -docstring 'Default: `python`' str jupyter_ascending_python_exec 'python'
  declare-option -hidden str jupyter_ascending_file

  remove-hooks global jupyter-ascending

  define-command -override jupyter-ascending-run-cell %{
    evaluate-commands %sh{
      $kak_opt_jupyter_ascending_python_exec -m jupyter_ascending.requests.execute --filename "$kak_bufname" --line "$kak_cursor_line" >/dev/null ||
        printf 'fail "ERROR: jupyter_ascending exited with: %d."' "$?"
    }
  }

  define-command -override -params ..1 -docstring %{
    Start notebook server for a .sync.{py,ipynb} file. If no arguments are given, use current file.
  } jupyter-ascending-start-notebook %{
    try %{ remove-hooks global jupyter-ascending }
    set-option current jupyter_ascending_file %val(bufname)
    evaluate-commands -try-client %opt(toolsclient) %{
      fifo -name "*jupyter-%opt(jupyter_ascending_file)*" -scroll -script %{
        filename="$1"
        if [ $# -eq 0 ]; then
          filename="$kak_opt_jupyter_ascending_file"
        fi

        printf 'Starting %s\n' "$filename"

        case "$filename" in
            *.sync.py)
              filename="${filename%.py}.ipynb"
              ;;
            *.sync.ipynb)
              ;;
            *) echo "Error: Filename must end in .sync.py or .sync.ipynb" >&2; exit 1 ;;
        esac

        printf 'Opening notebook on %s\n' "$filename"

        $kak_opt_jupyter_ascending_python_exec -m jupyter notebook "$filename"
      }
    }

    hook -group jupyter-ascending global BufWritePost .*\.sync\.py %{
      jupyter-ascending-sync-file %val(hook_param)
    }
  }
  complete-command jupyter-ascending-start-notebook file

  define-command -override -params 1 -docstring %{
    Sync file $1.
  } jupyter-ascending-sync-file %{
    evaluate-commands %sh{
      python -m jupyter_ascending.requests.sync --filename "$1" >/dev/null ||
        printf 'fail "ERROR: jupyter-ascending sync exited with: %d."' "$?"
    }
  }
  complete-command jupyter-ascending-sync-file file

  define-command -override -params 1 -docstring %{
    Create a file pair ($filename.sync.ipynb & $filename.sync.py).
    Jupyter_ascending works with file pairs.

    Params:
    - file path (e.g. `src/something`)
      => creates `src/something.sync.{py,ipynb}` for you.
  } jupyter-ascending-create-file-pair %{
    evaluate-commands %sh{
      $kak_opt_jupyter_ascending_python_exec -m jupyter_ascending.scripts.make_pair --base "$1" >/dev/null ||
        printf 'fail "ERROR: jupyter_ascending: file pair failed to create, exited with: %d."' "$?"
    }
  }
  complete-command jupyter-ascending-create-file-pair file

  try %{ declare-user-mode jupyter-ascending }
  map global jupyter-ascending e '<esc>: write -sync<ret>: jupyter-ascending-run-cell<ret>' -docstring 'Evaluate current cell'
  map global jupyter-ascending s '<esc>: jupyter-ascending-start-notebook<ret>' -docstring 'Start notebook'
  map global jupyter-ascending c '<esc>: jupyter-ascending-create-file-pair ' -docstring 'Create a file pair for path $1'
}
# hook global BufCreate .*\.sync\.py$ %{
#   map buffer user e '<esc>: enter-user-mode jupyter-ascending<ret>'
# }
