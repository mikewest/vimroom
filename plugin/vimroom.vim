"==============================================================================
"File:        vimroom.vim
"Description: Vaguely emulates a writeroom-like environment in Vim by
"             splitting the current window in such a way as to center a column
"             of user-specified width, wrap the text, and break lines.
"Maintainer:  Mike West <mike@mikewest.org>
"Version:     0.1
"Last Change: 2010-10-31
"License:     BSD <../LICENSE.markdown>
"==============================================================================

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Plugin Configuration
"

" The typical start to any vim plugin: If the plugin has already been loaded,
" exit as quickly as possible.
if exists( "g:loaded_vimroom_plugin" )
    finish
endif
let g:loaded_vimroom_plugin = 1

" The desired column width.  Defaults to 80:
if !exists( "g:vimroom_width" )
    let g:vimroom_width = 80
endif

" The minimum sidebar size.  Defaults to 5:
if !exists( "g:vimroom_min_sidebar_width" )
    let g:vimroom_min_sidebar_width = 5
endif

" The background color.  Defaults to "black"
if !exists( "g:vimroom_background" )
    let g:vimroom_background = "black"
endif

" The "scrolloff" value: how many lines should be kept visible above and below
" the cursor at all times?  Defaults to 999 (which centers your cursor in the 
" active window).
if !exists( "g:vimroom_scrolloff" )
    let g:vimroom_scrolloff = 999
endif


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Plugin Code
"

" Given the desired column width, and minimum sidebar width, determine
" the minimum window width necessary for splitting to make sense
let s:minwidth = g:vimroom_width + ( g:vimroom_min_sidebar_width * 2 )

" Save the current color scheme for reset later
let s:scheme = ""
if exists( "g:colors_name" )
    let s:scheme = g:colors_name
endif

" Save the current scrolloff value for reset later
let s:save_scrolloff = ""
if exists( "&scrolloff" )
    let s:save_scrolloff = &scrolloff
end

" We're currently in nonvimroomized state
let s:active   = 0

function! s:is_the_screen_wide_enough()
    return winwidth( winnr() ) >= s:minwidth
endfunction

function! s:sidebar_size()
    return ( winwidth( winnr() ) - g:vimroom_width - 2 ) / 2
endfunction

function! <SID>Vimroomize()
    if s:active == 1
        let s:active = 0
        only
        if s:scheme != ""
            exec( "colorscheme " . s:scheme ) 
        else
            hi clear
        endif
        if s:save_scrolloff != ""
            exec( "set scrolloff=" . s:save_scrolloff )
        endif
        set nowrap
        set nolinebreak
    else
        if s:is_the_screen_wide_enough()
            let s:active = 1
            let s:sidebar = s:sidebar_size()
            " Create the left sidebar
            exec( "silent leftabove " . s:sidebar . "vsplit new" )
            set noma
            wincmd l
            " Create the right sidebar
            exec( "silent rightbelow " . s:sidebar . "vsplit new" )
            set noma
            wincmd h
            " Setup wrapping, line breaking, and push the cursor down
            set wrap
            set linebreak
            if s:save_scrolloff != ""
                exec( "set scrolloff=".g:vimroom_scrolloff )
            endif
            " Hide distracting visual elements
            exec( "hi VertSplit ctermbg=" . g:vimroom_background . " ctermfg=" . g:vimroom_background . " guifg=" . g:vimroom_background . " guibg=" . g:vimroom_background )
            exec( "hi NonText ctermbg=" . g:vimroom_background . " ctermfg=" . g:vimroom_background . " guifg=" . g:vimroom_background . " guibg=" . g:vimroom_background )
            exec( "hi StatusLine ctermbg=" . g:vimroom_background . " ctermfg=" . g:vimroom_background . " guifg=" . g:vimroom_background . " guibg=" . g:vimroom_background )
            exec( "hi StatusLineNC ctermbg=" . g:vimroom_background . " ctermfg=" . g:vimroom_background . " guifg=" . g:vimroom_background . " guibg=" . g:vimroom_background )
            set fillchars+=vert:\ 
        endif
    endif
endfunction

" Create a mapping for the `Vimroomize` function
noremap <silent> <Plug>Vimroomize    :call <SID>Vimroomize()<CR>

" If no mapping exists, map it to `<Leader>V`.
if !hasmapto( '<Plug>Vimroomize' )
    nmap <silent> <Leader>V <Plug>Vimroomize
endif
