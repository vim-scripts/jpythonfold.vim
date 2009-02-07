" Fold routines for python code, version 2.5
" Source: http://www.vim.org/scripts/script.php?script_id=2527
" Last Change: 2009 Feb 6
" Author: Jurjen Bos
" Bug fixes and helpful comments: Grissiom, David Froger, Andrew McNabb

" Principles:
" - a def/class starts a fold
" a line with indent less than the previous def/class ends a fold
" empty lines are linked to the previous fold
" - optionally, you can get empty lines between folds, see (***)
" - another option is to ignore non-python files see (**)
" - you can also modify the def/class check, allowing for multiline def and class definitions
" comment lines outside a def/class are never folded
" other lines outside a def/class are folded together as a group
" Note:
" Vim 6 line numbers always take 8 columns, while vim 7 has a numberwidth variable
" you can change the 8 below to &numberwidth if you have vim 7,
" this is only really useful when you plan to use more than 8 columns (i.e. never)
" Note 2:
" class definitions are supposed to ontain a colon on the same line.
" function definitions are *not* required to have a colon, to allow for multiline defs.
" I you disagree, use instead of the pattern '^\s*\(class\s.*:\|def\s\)'
" to enforce : for defs:                     '^\s*\(class\|def\)\s.*:'
" to allow multiline class definitions:      '^\s*\(class\|def\)\s'
" you'll have to do this in two places.

" (**) Ignore non-python files
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
    " Auxiliary function; determines the indent level of the surrounding def/class
    " "global" lines are level 0, first def &shiftwidth, and so on
    " scan backwards for class/def that is shallower or equal
    let ind = 100
    let p = a:lnum
    while indent(p) >= 0
        let p = p - 1
        " skip deeper lines, comments and empty lines
        if indent(p) >= ind || getline(p) =~ '^$\|^\s*#'
            continue
        " indent is strictly less at this point: check for def/class
        elseif getline(p) =~ '^\s*\(class\s.*:\|def\s\)'
            " level is one more than this def/class
            return indent(p) + &shiftwidth
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
    if line =~ '^\s*\(class\s.*:\|def\s\)'
        return ">" . (ind / &shiftwidth + 1)
    " (***) uncomment the next two lines if you want empty lines/comment out of a fold
    "elseif line=~'^$\|^\s*#'
    "    return -1
    " some speed optimizations for common cases: same level if:
    " - indent positive and non-decreasing without def/class
    " (don't change this def/class pattern even if you change the others!)
    elseif ind>0 && ind>=indent(a:lnum-1) && getline(a:lnum-1)!~'^$\|^\s*\(def\|class\)\s'
        return '='
    " - empty lines before non-global lines
    elseif line == '' && getline(a:lnum+1) !~ '^[^ \t#]'
        return '='
    " - global code
    elseif line =~ '^[^ \t#]'
        return 1
    endif

    " figure out the surrounding class/def block
    let blockindent = GetBlockIndent(a:lnum)
    " global code follows: end all blocks
    if blockindent>0 && getline(a:lnum+1) =~ '^[^ \t#]'
        return '<1'
    " global code, with indented comments, form a block
    elseif blockindent==0 && line !~ '^#'
        return 1
    " regular line: deep line or non-comment line
    elseif ind>=blockindent || line !~ '^\s*#'
        return blockindent / &shiftwidth
    endif
    " shallow comment: level is determined by next line
    " search for next non-comment nonblank line
    let n = nextnonblank(a:lnum + 1)
    while n>0 && getline(n) =~ '^\s*#\|^$'
        let n = nextnonblank(n + 1)
    endwhile
    return GetBlockIndent(n) / &shiftwidth
endfunction
