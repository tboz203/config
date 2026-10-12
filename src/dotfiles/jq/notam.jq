# try to parse slog text key/value pairs into an object
def try_unslog:
  (
    [
      scan("(\\w+)=([^\\\"]\\S+|\\\".*?[^\\\\]\\\")") as [$key, $value]
      | {"key": $key, "value": $value | (fromjson? // .) | (fromjson? // .)}
    ]
    | if from_entries | keys | length > 0
      then from_entries
      else null end
  ) // .;

# strip ansi color escape sequences from a string
def unansi:
  (
    try gsub("\u001b\\[\\d+(;\\d+)*m"; "")
  ) // .;

# try to interpret gorm's colorized log messages
def try_ungorm:
  (
    unansi
    | try capture("\\[(?<duration>\\d+(?:\\.\\d+)?\\w*)\\] \\[rows:(?<rows>[^]]*)\\]\\s*(?<statement>.*)")
  ) // .;

