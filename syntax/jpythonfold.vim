" Fold routines for python code
" I have been using the standard python-fold.vim for years,
" and got more and more frustrated with it
" Author:	Jurjen Bos (foldexpr), Max Ischenko (foldtext), Robert
" Ames (line counts)
" Bug fix:	Drexler Christopher, Tom Schumm, Geoff Gerrietts

" Version: 2.4
" Last Change:	2009 Jan 27

" Principles:
" - a def/class starts a fold
" a line with indent less than the previous def/class ends a fold
" empty lines are linked to the previous fold
" comment lines outside a def/class are never folded
" other lines outside a def/class are folded together as a group

" Ignore non-python files (thanks to Grissiom)
" Commented out because some python files are not recognized by Vim
"if &filetype != 'python'
"    finish
"endif

setlocal foldmethod=expr
setlocal foldexpr=GetPythonFold(v:lnum)
setlocal foldtext=PythonFoldText()

function! PythonFoldText()
  let line = getline(v:foldstart)
  let nnum = nextnonblank(v:foldstart + 1)
  let nextline = getline(nnum)
  if nextline =~ '^\s\+"""$'
    let line = line . getline(nnum + 1)
  elseif nextline =~ '^\s\+"""'
    let line = line . ' ' . matchstr(nextline, '"""\zs.\{-}\ze\("""\)\?$')
  elseif nextline =~ '^\s\+"[^"]\+"$'
    let line = line . ' ' . matchstr(nextline, '"\zs.*\ze"')
  elseif nextline =~ '^\s\+pass\s*$'
    let line = line . ' pass'
  endif
  let size = 1 + v:foldend - v:foldstart
  if size < 10
    let size = " " . size
  endif
  if size < 100
    let size = " " . size
  endif
  if size < 1000
    let size = " " . size
  endif
  return size . " lines: " . line
endfunction


function! GetPythonFold(lnum)
    " Determine folding level in Python source
    let line = getline(a:lnum)
    " Empty line: keep with previous
    if line =~ '^$'
        return '='
    endif
    if line =~ '^\s*#'
        " Comment line: end fold if a zero-level line is coming up
        " Skip empty and comment lines
        " prevent hanging at EOF by checking indent >=0 (thanks to David Froger)
        let p = a:lnum + 1
        while getline(p) =~ '^\s*#\|^$' && indent(p) >= 0
            let p = p + 1
        endwhile
        if indent(p) > 0
            return '='
        else
            return 0
        endif
    endif
    let ind  = indent(a:lnum)
    " start fold for class and def
    if line =~ '^\s*\(def\|class\)\s'
        return ">" . (ind / &sw + 1)
    endif
    " zero-level lines get foldlevel 1
    if ind == 0
        return '1'
    endif
    pind = indent(a:lnum - 1)
    " line is indented more or equal
    if pind <= ind
        return '='
    endif
    " line is indented less: scan backwards
    let p = a:lnum - 1
    while indent(p) >= ind
        let p = p - 1
    endwhile
    " definition starts before us: end fold here
    if getline(p) =~ '^\s*\(def\|class\)\s'
        return "<" . (indent(p) / &sw + 2)
    endif
    return '='
endfunction
