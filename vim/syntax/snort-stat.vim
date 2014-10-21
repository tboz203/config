syn match integer   /\v \d+ /
syn match decimal   /\v\d+\.\d\d/
syn match prelude   /\v^(Subject|Events|Total|Source|Destination).*$/
syn match bar       /^=\+$/
syn match method    /\v<\u+(-\u+)?>([/ ]\w+)+\s*$/
syn match tagline   /\v^\w+( \w+)+$/
syn match addr      /\v\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/
syn match header    /\v^(\s+\%)?(\s+#)?\s+# of(\s+from)?(\s+to)?(\s+method)?$/

hi link header      Identifier
hi link bar         Statement
hi link tagline     Type
hi link addr        Special
hi link method      PreProc
hi link integer     Constant
hi link decimal     Constant
