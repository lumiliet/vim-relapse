
let s:relapsePort = 19191


fun! s:SendClojureCode(namespace, code, nreplPort)
    let json = json_encode({'namespace': a:namespace, 'code': a:code, 'port': a:nreplPort})
    let command = "echo " . shellescape(json) . " | nc localhost " . s:relapsePort . "\n"
    let result = system(command)

    if result == "java.net.ConnectException: Connection refused"
        return s:SendClojureCode(a:namespace, a:code, s:ResetPortNumber())
    elseif len(result)
        return result
    else
        return "No response"
    endif
endf

fun! Escape(json)
    return substitute(a:json, "'", "\\\\'", '')
endf

fun! s:ReadRange() range
    let code = join(getline(a:firstline, a:lastline), "\n")
    let portNumber = s:GetPortNumber()
    if portNumber
        echo s:SendClojureCode(s:ReadNamespace(), code, portNumber)
    else
        echo "No running repl for project"
    endif

    call s:CorrectCursorPosition()
endf

fun! s:CorrectCursorPosition()
    let pos = getcurpos()
    call cursor(pos[1], pos[4])
endf

fun! s:ReadNamespace()
    for lineNumber in range(0, line('$'))
        let match = matchlist(getline(lineNumber), '\_s*(ns\_s\_s*\(\_S\_S*\)')
        if len(match)
            return match[1]
        endif
    endfor

    return 'user'
endf

fun! s:GetPortNumber()
    if !exists('b:nreplPort')
        let b:nreplPort = s:ReadPortNumber()
    endif

    return b:nreplPort
endf

fun! s:ResetPortNumber()
    let b:nreplPort = s:ReadPortNumber()
    return b:nreplPort
endf

fun! s:ReadPortNumber()
    let nreplFilename = findfile('.nrepl-port', expand('%:p') . ';~/')
    if len(nreplFilename)
        return join(readfile(nreplFilename))
    else
        return 0
    endif
endf

command! -range Relapse <line1>,<line2>call s:ReadRange()

fun! Backwards()
    let pos = getpos('.')[2] - 1
    let code = getline(0, line('.') - 1) + [getline('.')[:pos]]

    return s:TraverseCode(code, -1)
endf

fun! Forwards()
    let pos = getpos('.')[2]
    let code = [getline('.')[pos:]] + getline(line('.') + 1, '$')

    return s:TraverseCode(code, 1)
endf

fun! s:TraverseCode(code, increment)

    let code = split(join(a:code, '\n'), '\zs')

    if a:increment < 0
        let code = reverse(code)
    endif

    let parenCount = 0
    let maxCount = 0
    let position = 0
    for index in range(0, len(code) -1)
        let char = code[index]
        if char == ')'
            let parenCount = parenCount + a:increment
        elseif char == '('
            let parenCount = parenCount - a:increment
        endif

        if parenCount > maxCount
            let maxCount = parenCount
            let position = index
        endif
    endfor

    if maxCount == 0
        return ""
    elseif a:increment < 0
        return join(reverse(code[:position]), '')
    else
        return join(code[:position], '')
    endif
endf

fun! FindParentForm()
    return Backwards() . Forwards()
endf
