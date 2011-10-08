"==============================================================================
"File:        vimroom.vim
"Description: Vaguely emulates a writeroom-like environment in Vim by
"             splitting the current window in such a way as to center a column
"             of user-specified width, wrap the text, and break lines.
"Maintainer:  Mike West <mike@mikewest.org>
"Version:     0.7
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

" The sidebar height.  Defaults to 3:
if !exists( "g:vimroom_sidebar_height" )
    let g:vimroom_sidebar_height = 3
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

" Should Vimroom map navigational keys (`<Up>`, `<Down>`, `j`, `k`) to navigate
" "display" lines instead of "logical" lines (which makes it much simpler to deal
" with wrapped lines). Defaults to `1` (on). Set to `0` if you'd prefer not to
" run the mappings.
if !exists( "g:vimroom_navigation_keys" )
    let g:vimroom_navigation_keys = 1
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
if exists( "&t_mr" )
    let s:save_t_mr = &t_mr
end

" Save the current scrolloff value for reset later
let s:save_scrolloff = ""
if exists( "&scrolloff" )
    let s:save_scrolloff = &scrolloff
end

" Save the current `laststatus` value for reset later
let s:save_laststatus = ""
if exists( "&laststatus" )
    let s:save_laststatus = &laststatus
endif

" Save the current `textwidth` value for reset later
let s:save_textwidth = ""
if exists( "&textwidth" )
    let s:save_textwidth = &textwidth
endif

" We're currently in nonvimroomized state
let s:active   = 0

function! s:is_the_screen_wide_enough()
    return winwidth( winnr() ) >= s:minwidth
endfunction

function! s:sidebar_size()
    return ( winwidth( winnr() ) - g:vimroom_width - 2 ) / 2
endfunction

function! <SID>VimroomToggle()
    if s:active == 1
        let s:active = 0
        " Close all other windows
        only
        " Reset color scheme (or clear new colors, if no scheme is set)
        if s:scheme != ""
            exec( "colorscheme " . s:scheme ) 
        else
            hi clear
        endif
        if s:save_t_mr != ""
            exec( "set t_mr=" .s:save_t_mr )
        endif
        " Reset `scrolloff` and `laststatus`
        if s:save_scrolloff != ""
            exec( "set scrolloff=" . s:save_scrolloff )
        endif
        if s:save_laststatus != ""
            exec( "set laststatus=" . s:save_laststatus )
        endif
        if s:save_textwidth != ""
            exec( "set textwidth=" . s:save_textwidth )
        endif
        " Remove wrapping and linebreaks
        set nowrap
        set nolinebreak
    else
        if s:is_the_screen_wide_enough()
            let s:active = 1
            let s:sidebar = s:sidebar_size()
            " Turn off status bar
            if s:save_laststatus != ""
                set laststatus=0
            endif
            " Create the left sidebar
            exec( "silent leftabove " . s:sidebar . "vsplit new" )
            set noma
            set nocursorline
            wincmd l
            " Create the right sidebar
            exec( "silent rightbelow " . s:sidebar . "vsplit new" )
            set noma
            set nocursorline
            wincmd h
            if g:vimroom_sidebar_height
                " Create the top sidebar
                exec( "silent leftabove " . g:vimroom_sidebar_height . "split new" )
                set noma 
                set nocursorline
                wincmd j
                " Create the bottom sidebar
                exec( "silent rightbelow " . g:vimroom_sidebar_height . "split new" )
                set noma
                set nocursorline
                wincmd k
            endif
            " Setup wrapping, line breaking, and push the cursor down
            set wrap
            set linebreak
            if s:save_textwidth != ""
                exec( "set textwidth=".g:vimroom_width )
            endif
            if s:save_scrolloff != ""
                exec( "set scrolloff=".g:vimroom_scrolloff )
            endif

            " Setup navigation over "display lines", not "logical lines" if
            " mappings for the navigation keys don't already exist.
            if g:vimroom_navigation_keys
                try
                    noremap     <unique> <silent> <Up> g<Up>
                    noremap     <unique> <silent> <Down> g<Down>
                    noremap     <unique> <silent> k gk
                    noremap     <unique> <silent> j gj
                    inoremap    <unique> <silent> <Up> <C-o>g<Up>
                    inoremap    <unique> <silent> <Down> <C-o>g<Down>
                catch /E227:/
                    echo "Navigational key mappings already exist."
                endtry
            endif

            " Hide distracting visual elements
            exec( "hi VertSplit ctermbg=" . g:vimroom_background . " ctermfg=" . g:vimroom_background . " guifg=" . g:vimroom_background . " guibg=" . g:vimroom_background )
            exec( "hi NonText ctermbg=" . g:vimroom_background . " ctermfg=" . g:vimroom_background . " guifg=" . g:vimroom_background . " guibg=" . g:vimroom_background )
            exec( "hi StatusLine ctermbg=" . g:vimroom_background . " ctermfg=" . g:vimroom_background . " guifg=" . g:vimroom_background . " guibg=" . g:vimroom_background )
            exec( "hi StatusLineNC ctermbg=" . g:vimroom_background . " ctermfg=" . g:vimroom_background . " guifg=" . g:vimroom_background . " guibg=" . g:vimroom_background )
            set t_mr=""
            set fillchars+=vert:\ 
        endif
    endif
endfunction

" Create a mapping for the `VimroomToggle` function
noremap <silent> <Plug>VimroomToggle    :call <SID>VimroomToggle()<CR>

" Create a `VimroomToggle` command:
command -nargs=0 VimroomToggle call <SID>VimroomToggle()

" If no mapping exists, map it to `<Leader>V`.
if !hasmapto( '<Plug>VimroomToggle' )
    nmap <silent> <Leader>V <Plug>VimroomToggle
endif
