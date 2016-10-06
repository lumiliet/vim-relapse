# vim-relapse

Evaluate clojure code in an nrepl via [relapse](https://github.com/lumiliet/relapse).

Just run `Relapse` in Vim to evaluate current line. Or use with a range to evaluate multiple lines. For example `0,3Relapse` will evaluate lines 0 through 3. `%Relapse` will evaluate the entire buffer. You can also select a range in visual mode first and then run `Relapse`.

Requires a running [relapse](https://github.com/lumiliet/relapse) server.
