#' check if a url is okay
#' 
#' @export
#' @param x either a URL as a character string, or an object of 
#' class [HttpClient]
#' @param status (integer) one or more HTTP status codes, must be integers.
#' default: `200L`, since this is the most common signal
#' that a URL is okay, but there may be cases in which your URL
#' is okay if it's a `201L`, or some other status code.
#' @param info (logical) in the case of an error, do you want a 
#' `message()` about it? Default: `TRUE`
#' @param verb (character) use "head" (default) or "get" HTTP verb
#' for the request. note that "get" will take longer as it returns a
#' body. however, "verb=get" may be your only option if a url
#' blocks head requests
#' @param ... args passed on to [HttpClient]
#' @return a single boolean, if `TRUE` the URL is up and okay, 
#' if `FALSE` it is down.
#' @details We internally verify that status is an integer and 
#' in the known set of HTTP status codes, and that info is a boolean
#' 
#' You may have to fiddle with the parameters to `ok()` as well as
#' curl options to get the "right answer". If you think you are getting
#' incorrectly getting `FALSE`, the first thing to do is to pass in
#' `verbose=TRUE` to `ok()`. That will give you verbose curl output and will
#' help determine what the issue may be. Here's some different scenarios:
#' 
#' - the site blocks head requests: some sites do this, try `verb="get"`
#' - it will be hard to determine a site that requires this, but it's
#' worth trying a random useragent string, e.g., `ok(useragent = "foobar")`
#' - some sites are up and reachable but you could get a 403 Unauthorized
#' error, there's nothing you can do in this case other than having access
#' - its possible to get a weird HTTP status code, e.g., LinkedIn gives
#' a 999 code, they're trying to prevent any programmatic access
#' 
#' @examples \dontrun{
#' # 200
#' ok("https://google.com") 
#' # 200
#' ok("https://httpbin.org/status/200")
#' # more than one status
#' ok("https://google.com", status = c(200L, 202L))
#' # 404
#' ok("https://httpbin.org/status/404")
#' # doesn't exist
#' ok("https://stuff.bar")
#' # doesn't exist
#' ok("stuff")
#' 
#' # use get verb instead of head
#' ok("http://animalnexus.ca")
#' ok("http://animalnexus.ca", verb = "get")
#' 
#' # some urls will require a different useragent string
#' # they probably regex the useragent string
#' ok("https://doi.org/10.1093/chemse/bjq042")
#' ok("https://doi.org/10.1093/chemse/bjq042", verb = "get", useragent = "foobar")
#' 
#' # with HttpClient
#' z <- crul::HttpClient$new("https://httpbin.org/status/404", 
#'  opts = list(verbose = TRUE))
#' ok(z)
#' }
ok <- function(x, status = 200L, info = TRUE, verb = "head", ...) {
  UseMethod("ok")
}

#' @export
ok.default <- function(x, status = 200L, info = TRUE, verb = "head", ...) {
  stop("no 'ok' method for ", class(x)[[1L]], call. = FALSE)
}

#' @export
ok.character <- function(x, status = 200L, info = TRUE, verb = "head", ...) {
  z <- crul::HttpClient$new(x, opts = list(...))
  ok(z, status, info, verb, ...)
}

#' @export
ok.HttpClient <- function(x, status = 200L, info = TRUE, verb = "head", ...) {
  assert(info, "logical")
  assert(status, "integer")
  assert_opts(verb, c("head", "get"))
  
  for (i in seq_along(status)) {
    ts <- tryCatch(httpcode::http_code(status[i]), error = function(e) e)
    if (inherits(ts, "error"))
      stop("status [", status[i], "] not in acceptable set")
  }

  w <- tryCatch(x$verb(verb), error = function(e) e)
  if (inherits(w, "error")) {
    if (info) message(w$message)
    return(FALSE)
  }
  w$status_code %in% status
}
