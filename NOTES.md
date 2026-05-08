
> We pull through `codeload.github.com` rather than
> `raw.githubusercontent.com` because the latter is fronted by a 5-minute
> Fastly cache that ignores `Cache-Control: no-cache` and query-string
> cache-busters. `codeload` serves the tarball fresh, so the snippet
> always lands the latest commit.
