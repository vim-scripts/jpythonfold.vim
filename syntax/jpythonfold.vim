" Fold routines for python code, version 2.3
" Source: http://www.vim.org/scripts/script.php?script_id=2527
" Last Change: 2009 Feb 4
" Author: Jurjen Bos
" Bug fixes and comments: Grissiom, David Froger, Andrew McNabb

" Principles:
" - a def/class starts a fold
" a line with indent less than the previous def/class ends a fold
" empty lines are linked to the previous fold
" optionally, you can get empty lines between folds (see ***)
" comment lines outside a def/class are never folded
" other lines outside a def/class are folded together as a group
" Note:
" Vim 6 line numbers always take 8 columns, while vim 7 has a numberwidth variable
" you can change the 8 if you have vim 7, and use more than 8 columns

" Ignore non-python files
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
  "get the document string.
  if nextline =~ "^\\s\\+[\"']\\{3}\\s*$"
      let line = line . " " . matchstr(getline(nextnonblank(nnum + 1)), '^\s*\zs.*\ze$')
  elseif nextline =~ "^\\s\\+[\"']\\{1,3}"
      let line = line." ".matchstr(nextline, "^\\s\\+[\"']\\{1,3}\\zs.\\{-}\\ze['\"]\\{0,3}$")
  elseif nextline =~ '^\s\+pass\s*$'
    let line = line . ' pass'
  endif
  "compute the width of the visible part of the window (see Note above)
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
    let p = nextnonblank(a:lnum)
    " skip comments and empty lines, to get proper initial indent
    while p>0 && getline(p) =~ '^\s*#\|^$'
        let p = nextnonblank(p + 1)
    endwhile
    let ind = indent(p)
    while indent(p) >= 0
        let p = p - 1
        " skip deeper lines, comments and empty lines
        if indent(p) >= ind || getline(p) =~ '^$\|^\s*#'
            continue
        " indent is strictly less at this point: check for def/class
        elseif getline(p) =~ '^\s*\(def\|class\)\s.*:'
            " this is the level!
            return indent(p) + &sw
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
    let ind = indent(a:lnum)
    " class and def start a fold
    if line =~ '^\s*\(def\|class\)\s.*:'
        return ">" . (ind / &sw + 1)
    " *** uncomment next two lines if you want empty lines/comment out of a fold
    "elseif line=~'^$\|^\s*#'
    "    return -1
    " optimization for speed: same level if:
    " line is no comment, and previous line is not special, and indent doesn't increase
    " (note that empty lines are are handled by this case too)
    elseif line!~'^\s*#' && getline(a:lnum-1)!~'^$\|^\s*\(#\|def\s\|class\s\)' && indent(a:lnum-1)>=ind
        return '='
    endif
    " figure out the surrounding class/def block
    let blockindent = GetBlockIndent(a:lnum)
    " global code, with indented comments, form a block
    if blockindent==0 && line !~ '^#'
        return 1
    " regular line: deep line or non-comment line
    elseif ind>=blockindent || line !~ '^\s*#'
        return blockindent / &sw
    endif
    " shallow comment: level is determined by next line
    " search for next non-comment nonblank line
    let n = nextnonblank(a:lnum + 1)
    while n>0 && getline(n) =~ '^\s*#\|^$'
        let n = nextnonblank(n + 1)
    endwhile
    return GetBlockIndent(n) / &sw
endfunction
