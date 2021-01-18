if !hlexists('SluiceVisibleArea')
  hi link SluiceVisibleArea Normal
endif
if !hlexists('SluiceCursor')
  hi link SluiceCursor Normal
endif
if !hlexists('SluiceColumn')
  hi link SluiceColumn SignColumn
endif

lua require'sluice'
