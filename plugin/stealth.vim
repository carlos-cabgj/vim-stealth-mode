let s:cryptWorking               = 0
let s:passwords                  = {}
let g:OneIdeDeletePathernEncrypt = "~|.swp"
let g:ignoreFile                 = '.gitignore'
let g:OneIdeVimEspaceRegex       = '~\[|^'

command! -n=0 -bar OneProjectAddPassword :call stealth#addPassword()
command! -n=0 -bar OneProjectDecrypt :call stealth#projectDecrypt()
command! -n=0 -bar OneProjectEncrypt :call stealth#ProjectEncrypt()

augroup oneenc
    autocmd BufReadPre   * call s:onReadOneIdePre(expand("<amatch>"))
    autocmd BufWritePre  * call s:onSaveOneIdePre(expand("<amatch>"))
    autocmd BufWritePost * call s:onSaveOneIdePos()
    autocmd VimEnter     * setlocal cm=blowfish2
augroup end

function! s:getTemperedPass(passChain, file)

    let salt = a:passChain['salt']
    let pass = a:passChain['pass']

    if salt == ''
        return pass
    else
        let clean               = s:changeAlphabet(substitute(tolower(a:file), '[^a-z0-1]', '', 'g'))
        let saltConverted       = s:changeAlphabet(substitute(tolower(salt), '[^a-z0-1]', '', 'g'))
        let saltConvertedToPass = saltConverted * clean / len(clean)
        let cleanSize           = len(clean)
        let saltJump            = len(salt)

        if saltJump > len(pass)
            while saltJump > len(pass)
                let saltJump = saltJump / 3
            endwhile
        endif
        if saltJump <= 1
            let saltJump = 1
        endif

        let i = 0
        let n = 0
        let endTransform = 0
        let textReturn = ''

        while cleanSize >= n

            if n > 0
                let pass = textReturn
                let textReturn = ''
            endif

            let p = 0
            while p < len(pass)
                if p % saltJump == 0
                    let textReturn = textReturn . saltConvertedToPass[n]
                    let n = n + 1
                endif
                let textReturn = textReturn . pass[p]
                let p = p + 1
            endwhile
        endwhile
        return textReturn
    endif
endfunction


function! s:changeAlphabet(text)

    let alphabet = {0 : 0, 1 : 1, 2 : 2, 3 : 3, 4 : 4, 5 : 5, 6 : 6, 7 : 7, 8 : 8, 9 : 9, 'a' : 1, 'b' : 2, 'c' : 3, 'd' : 4, 'e' : 5, 'f' : 6, 'g' : 7, 'h' : 8, 'i' : 9, 'j' : 10, 'k' : 11, 'l' : 12, 'm' : 13, 'n' : 14, 'o' : 15, 'p' : 16, 'q' : 17, 'r' : 18, 's' : 19, 't' : 20, 'u' : 21, 'v' : 22, 'x' : 23, 'w' : 24, 'y' : 25, 'z' : 26}

    let cleanSize = len(a:text)
    let i = 0
    let textReturn = ''

    while i < cleanSize
        let textReturn = textReturn . alphabet[a:text[i]]
        let i = i + 1
    endwhile

    return textReturn
endfunction

function! stealth#disableEncrypt()
    set swapfile
    set backup
    set writebackup
    set viminfo='1000,<9999,s100
endfunction

function! stealth#enableEncrypt()
    set noundofile
    set noswapfile
    set nobackup
    set nowritebackup
    set viminfo=
    set cryptmethod=blowfish2
    set cm=blowfish2
endfunction

function! stealth#setPassSalt(path)
    let name = inputsecret(onefunctions#i18n('saltpasstoenc'))
    let s:passwords[a:path] = {'salt' : name, 'pass' : ''}
endfunction

function! stealth#setPassValue(path)
    let name = inputsecret(onefunctions#i18n('passtoenc'))
    let s:passwords[a:path]['pass'] = name
endfunction

function! stealth#setPass(path)
    :call stealth#setPassSalt(a:path)
    :call stealth#setPassValue(a:path)
endfunction

function stealth#addPassword()
    let pathSearch = onefunctions#getFileInTree('.one-project')
    let config = onefunctions#readConfig(pathSearch[0])

    if pathSearch != []
        :call stealth#setPass(pathSearch[1])
    endif
endfunction

function! s:onReadOneIdePre(file)
    let pathSearch = onefunctions#getFileInTree('.one-project')
    if pathSearch != []
        let config       = onefunctions#readConfig(pathSearch[0])
        let pathIgnore = onefunctions#getFileInTree(g:ignoreFile)
        let ignored      = []

        if pathIgnore != []
            let ignored = onefunctions#readIgnore(pathIgnore[0])
        endif

        let l:endpath = substitute(expand('%:p'), escape(pathSearch[1], '\'), "", "")

        if onefunctions#regexTestFiles(ignored, l:endpath) == 0
            if has_key(config, 'encryption') == 1 && config['encryption']['status'] == 1
                :call stealth#enableEncrypt()
                if has_key(s:passwords, pathSearch[1]) == 0
                    :call stealth#setPass(pathSearch[1])
                endif
                silent! exec ':set key='.s:getTemperedPass(s:passwords[pathSearch[1]], expand('%:t'))
            endif
        endif
    endif
endfunction

function s:onSaveOneIdePre(file)
    let pathSearch = onefunctions#getFileInTree('.one-project')
    if pathSearch != []
        let config = onefunctions#readConfig(pathSearch[0])
        let file = ''
        let l:endpath = substitute(expand('%:p'), escape(pathSearch[1], '\'), "", "")

        if has_key(config, 'encryption') == 1 && config['encryption']['status'] == 1

            let pathIgnore = onefunctions#getFileInTree(g:ignoreFile)
            let ignored      = []
            let pathDecode = config['encryption']['pathDecode']

            if pathIgnore != []
                let ignored = onefunctions#readIgnore(pathIgnore[0])
            endif


            if has_key(s:passwords, pathSearch[1]) == 1 && onefunctions#regexTestFiles(ignored, expand('%:p')) == 0
                if s:cryptWorking == 0
                    call s:savePreOnVim(pathSearch, pathDecode, l:endpath)
                endif
            endif
        else
            call stealth#disableEncrypt()
        endif

    endif
endfunction

" Method responsable for to send the content decrypted to other location
function s:savePreOnVim(pathSearch, pathDecode, endpath)
    call stealth#enableEncrypt()
 	:set key=
    let l:endpathFolder = substitute(expand('%:p:h').g:sep, escape(a:pathSearch[0], '\'), "", "")

    if a:pathDecode != ''
        call onefunctions#log(l:endpathFolder)
        if isdirectory(l:endpathFolder) == 0
            :call mkdir(l:endpathFolder, 'p')
        endif

        silent! exec ':w! '.a:pathDecode.a:endpath
        " This block is for further compatibility with autodeploy
        " if has_key(config, 'autodeploy') == 1 && config['autodeploy']['status'] == 1
        "     if exists("deploy#onSaveAutoDeploy")
        "         let file = pathDecode.l:endpath
        "         :call deploy#onSaveAutoDeploy(config, file, l:endpath)
        "     endif
        " endif
    endif

    silent! exec ':set key='.s:getTemperedPass(s:passwords[a:pathSearch[1]], expand('%:t'))
endfunction

function s:onSaveOneIdePos()

    let oneProjectDotFile = onefunctions#getFileInTree('.one-project')

    if oneProjectDotFile != []
        let config       = onefunctions#readConfig(oneProjectDotFile[0])
        let pathIgnore   = onefunctions#getFileInTree(g:ignoreFile)
        let ignored      = []

        if pathIgnore != []
            let ignored = onefunctions#readIgnore(pathIgnore[0])
        endif

        let l:endpath = substitute(expand('%:p'), escape(oneProjectDotFile[1], '\'), "", "")

        if onefunctions#regexTestFiles(ignored, l:endpath) == 0
            if has_key(config, 'encryption') == 1 && config['encryption']['status'] == 1
                if has_key(s:passwords, oneProjectDotFile[1]) == 1 && s:cryptWorking == 0
                    :set key=
                endif
            endif
        endif
    endif
endfunction

function stealth#ProjectEncrypt()

    let pathSearch = onefunctions#getFileInTree('.one-project')
    let pathIgnore = onefunctions#getFileInTree(g:ignoreFile)
    let ignored = []

    if pathIgnore != []
        let ignored = onefunctions#readIgnore(pathIgnore[0])
    endif

    if pathSearch != []

        let l:globstring = globpath(pathSearch[1], '**')
        let l:globlist   = split(l:globstring, "\n")
        let s:path       = split(pathSearch[1], g:sep)
        let config       = onefunctions#readConfig(pathSearch[0])

        if has_key(config, 'encryption') == 1 && config['encryption']['status'] == 1
            if has_key(s:passwords, pathSearch[1]) == 0 || empty(s:passwords[pathSearch[1]])
                :call stealth#setPass(pathSearch[1])
            endif
            if has_key(s:passwords, pathSearch[1]) == 0 || empty(s:passwords[pathSearch[1]])
                :echo onefunctions#i18n('passnotvalid')
            else
                :call stealth#enableEncrypt()
                let s:cryptWorking = 1
                for l:node in l:globlist
                    let l:endpath = substitute(l:node, escape(pathSearch[1], '\'), "", "")

                    if filereadable(l:node)
                        if matchstr(l:node, escape(g:OneIdeDeletePathernEncrypt, g:OneIdeVimEspaceRegex)) != ''
                            :call delete(l:node)
                        else
                            if onefunctions#regexTestFiles(ignored, l:node) == 0
                                silent! exec ':set key='.s:getTemperedPass(s:passwords[pathSearch[1]], expand('%:t'))
                                silent! exec ':e '.l:node
                                silent! exec ':set key='.s:getTemperedPass(s:passwords[pathSearch[1]], expand('%:t'))
                                silent! exec ':w!'
                                silent! norm gd
                            endif
                        endif
                        if matchstr(l:node, escape(g:OneIdeDeletePathernEncrypt, g:OneIdeVimEspaceRegex)) != ''
                            :call delete(l:node)
                        endif
                    endif
                endfor
                let s:cryptWorking = 0
            endif
        endif
    else
        :echo onefunctions#i18n('thisprojdhaconf')
    endif
endfunction

function stealth#projectDecrypt()
    let pathSearch = onefunctions#getFileInTree('.one-project')
    if pathSearch != []
        let l:globstring = globpath(pathSearch[1], '**')
        let l:globlist   = split(l:globstring, "\n")
        let s:path       = split(pathSearch[1], g:sep)
        let config       = onefunctions#readConfig(pathSearch[0])
        let pathIgnore   = onefunctions#getFileInTree(g:ignoreFile)
        let ignored      = []

        if pathIgnore != []
            let ignored = onefunctions#readIgnore(pathIgnore[0])
        endif

        if config['encryption']['status']
            let pathDecode = config['encryption']['pathDecode']
            if has_key(s:passwords, pathSearch[1]) == 0 || empty(s:passwords[pathSearch[1]])
                :call stealth#setPass(pathSearch[1])
            endif
            if has_key(s:passwords, pathSearch[1]) == 0 || empty(s:passwords[pathSearch[1]])
                :echo onefunctions#i18n('passnotvalid')
            else
                :call delete(pathDecode, 'rf')
                :call mkdir(pathDecode, 'p')
                :call stealth#enableEncrypt()
                :echo onefunctions#i18n('starting')
                let s:cryptWorking = 1
                for l:node in l:globlist
                    let l:endpath = substitute(l:node, escape(pathSearch[1], '\'), "", "")
                    if onefunctions#regexTestFiles(ignored, l:endpath) == 0
                        if filereadable(l:node) == 0
                            :call mkdir(escape(pathDecode.l:endpath, '\'), 'p')
                        else
                            exec ':set key='.s:getTemperedPass(s:passwords[pathSearch[1]], expand('%:t'))
                            silent! exec ':e '.l:node
                            :set key=
                            silent! exec ':w '.pathDecode.l:endpath
                            norm gd
                        endif
                    endif
                endfor
                let s:cryptWorking = 0
                :echo onefunctions#i18n('decryptSuccess')
            endif
        endif
    else
        :echo onefunctions#i18n('thisprojdhaconf')
    endif
endfunction
