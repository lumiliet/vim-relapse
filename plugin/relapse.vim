
let s:relapsePort = 19191


fun! s:SendClojureCode(namespace, code, nreplPort)
    let command = json_encode({'namespace': a:namespace, 'code': a:code, 'port': a:nreplPort})
    let completeCommand = "echo '" . command . "' | nc localhost " . s:relapsePort
    let result = system(completeCommand)

    if result == "java.net.ConnectException: Connection refused"
        return s:SendClojureCode(a:namespace, a:code, s:ResetPortNumber())
    elseif len(result)
        return result
    else
        return "No response"
    endif
endf

fun! s:ReadRange() range
    let code = join(getline(a:firstline, a:lastline), "\n")
    let portNumber = s:GetPortNumber()
    if portNumber
        echo s:SendClojureCode(s:ReadNamespace(), code, portNumber)
    else
        echo "No running repl for project"
    endif
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
