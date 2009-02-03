" Fold routines for python code, version 2.1
" Last Change: 2009 Feb 2, when I had better go to bed
" Author: Jurjen Bos (foldexpr, and most of foldtext), Max Ischenko (foldtext)
" Bug fixes: Grissiom, David Froger

" Principles:
" - a def/class starts a fold
" a line with indent less than the previous def/class ends a fold
" empty lines are linked to the previous fold
" comment lines outside a def/class are never folded
" other lines outside a def/class are folded together as a group

" New idea:
" Comment lines fold with the definition if deep enough;
" shallower comments go one level up. We'll try to map this with the global comment code

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
  "get the document string. This is ugly, but I can't fix it
  if nextline =~ "^\\s\\+[\"']\\{1,3}"
      let line = matchstr(nextline, "^\\s\\+[\"']\\{1,3}\\zs.\\{-}\\ze['\"]\\{0,3}$")
  elseif nextline =~ '^\s\+pass\s*$'
    let line = line . ' pass'
  endif
  "compute the width of the visible part of the window
  let w = winwidth(0) - &foldcolumn - (&number ? 8 : 0)
  let size = 1 + v:foldend - v:foldstart
  "compute expansion string
  let spcs = '................'
  while strlen(spcs) < w
    let spcs = spcs . spcs
  endwhile
  "expand tabs (mail me if you have tabstop>10)
  let onetab = strpart('          ', 0, &tabstop)
  let line = substitute(line, '\t', onetab, 'g')
  return strpart(line.spcs, 0, w-strlen(size)-7).'.'.size.' lines'
endfunction

function! GetBlockIndent(lnum)
    " Auxiliary function; determines the indent level of the def/class
    " "global" lines are level 0, first def &sw, and so on
    " scan backwards for class/def that is shallower or equal
    let p = a:lnum
    " skip comments and empty lines, since we don't trust their indent
    while indent(p)>=0 && getline(p) =~ '^\s*#\|^$'
        let p = p + 1
    endwhile
    let ind = indent(p)
    while indent(p)>=0
        let p = p - 1
        " skip comments and empty lines
        if getline(p) =~ '^$\|^\s*#'
            continue
        " deeper: continue search
        elseif indent(p) >= ind
            continue
        " indent is strictly less at this point: check for def/class
        elseif getline(p) =~ '^\s*\(def\|class\)\s'
            " this is the level!
            return indent(p)+&sw
        " zero-level regular line
        elseif indent(p) == 0
            return 0
        endif
        " shallower line that is neither class nor def: continue search at new level
        let ind = indent(p)
    endwhile
    "beginning of file
    return 0
endfunction

function! GetPythonFold(lnum)
    " Determine folding level in Python source
    let line = getline(a:lnum)
    " Empty line: keep with previous
    if line == ''
        return '='
    endif
    let ind = indent(a:lnum)
    " class and def start a fold
    if line =~ '^\s*\(def\|class\)\s'
        return ">" . (ind / &sw + 1)
    endif
    " figure out the surrounding class/def block
    let blockindent = GetBlockIndent(a:lnum)
    " global code, with indented comments, form a block
    if blockindent==0 && line !~ '^#'
        return 1
    " regular line: deep line or non-comment line
    elseif ind>=blockindent || line !~ '^\s*#'
        return blockindent/&sw
    endif
    " shallow comment: level is determined by next line
    " search for next non-comment nonblank line
    let n = a:lnum + 1
    while indent(n)>=0 && getline(n) =~ '^\s*#\|^$'
        let n = n+1
    endwhile
    return GetBlockIndent(n)/&sw
endfunction
