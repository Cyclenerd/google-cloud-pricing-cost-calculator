# How to contribute

First off, thanks for taking the time to contribute!

## Submitting changes

Please send a GitHub Pull Request with a clear list of what you've done (read more about [pull requests](http://help.github.com/pull-requests/)).

Always write a clear log message for your commits. One-line messages are fine for small changes, but bigger changes should look like this:

```
$ git commit -m "A brief summary of the commit
> 
> A paragraph describing what changed and its impact."
```

## Coding style

Start reading the code and you'll get the hang of it. It is optimized for readability:

* Please name new Perl scripts according to the following pattern `a-z 0-9 _` (`[\w\d_]+\.pl`).
* Please name new CSV files according to the following pattern `a-z 0-9 _` (`[\w\d_]+\.csv`).
* If you need a new Perl module, please adapt the docs, cpanfile, GitHub Actions and Docker images as well.
* Please also update the documentation.
* Space before the opening curly of a multi-line BLOCK.
* No space before the semicolon.
* Space around most operators.
* No space between function name and its opening parenthesis.
* Line up corresponding things vertically, especially if it'd be too long to fit on one line anyway.
* Please use tabs to indent.
* For Go please run `gofmt -s` and `golangci-lint`
* Be nice.

One more thing:

* Keep it simple! 👍

Thanks! ❤️❤️❤️
