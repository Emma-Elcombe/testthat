#' Create a test.
#'
#' A test encapsulates a series of expectations about small, self-contained
#' set of functionality. Each test is contained in a \link{context} and
#' contains multiple expectations.
#'
#' Tests are evaluated in their own environments, and should not affect
#' global state.
#'
#' When run from the command line, tests return \code{NULL} if all
#' expectations are met, otherwise it raises an error.
#'
#' @param desc test name.  Names should be kept as brief as possible, as they
#'   are often used as line prefixes.
#' @param code test code containing expectations
#' @export
#' @examples
#' test_that("trigonometric functions match identities", {
#'   expect_equal(sin(pi / 4), 1 / sqrt(2))
#'   expect_equal(cos(pi / 4), 1 / sqrt(2))
#'   expect_equal(tan(pi / 4), 1)
#' })
#' # Failing test:
#' \dontrun{
#' test_that("trigonometric functions match identities", {
#'   expect_equal(sin(pi / 4), 1)
#' })
#' }
test_that <- function(desc, code) {
  code <- substitute(code)
  test_code(desc, code, env = parent.frame())
}

test_code <- function(description, code, env) {
  get_reporter()$start_test(description)
  on.exit(get_reporter()$end_test())

  ok <- TRUE
  register_expectation <- function(e) {
    e <- as.expectation(e, srcref = find_test_srcref())
    ok <<- ok && expectation_success(e)
    get_reporter()$add_result(e)
  }

  frame <- sys.nframe()
  handle_error <- function(e) {
    # Capture call stack, removing last two calls from end (added by
    # withCallingHandlers), and first frame + 7 calls from start (added by
    # tryCatch etc)
    e$calls <- utils::head(sys.calls()[-seq_len(frame + 7)], -2)

    register_expectation(e)
    signalCondition(e)
  }
  handle_expectation <- function(e) {
    register_expectation(e)
    invokeRestart("continue_test")
  }
  handle_message <- function(e) {
    invokeRestart("muffleMessage")
  }
  handle_skip <- function(e) {
    register_expectation(e)
    signalCondition(e)
  }

  test_env <- new.env(parent = env)
  tryCatch(
    withCallingHandlers(
      eval(code, test_env),
      expectation = handle_expectation,
      skip =        handle_skip,
      message =     handle_message,
      error =       handle_error
    ),
    # error/skip silently terminate code
    error = function(e) {},
    skip =  function(e) {}
  )

  invisible(ok)
}

# find the srcref of the test call, or NULL
find_test_srcref <- function() {
  # candidate frame is not in the testthat package,
  # its call matches expect_* and has parsing info attached
  .is_test_frame <- function(i) {
    # is enclosure of the frame containing the call inside testthat package ?
    inside <- identical(environmentName(parent.env(sys.frame(i - 1)))
      , 'testthat')
    match_expect <- any(grepl('expect_', sys.call(i)))
    has_srcref <- !is.null(attr(sys.call(i), 'srcref'))

    !inside && match_expect && has_srcref
  }

  # find the first call (tracing back) that seems good
  nbe <- Find(.is_test_frame, seq_len(sys.nframe()), right = TRUE)

  if (length(nbe) == 0 || is.na(nbe)) {
    return(NULL)
  }

  cc <- sys.call(nbe)
  src <- attr(cc, 'srcref')
  if (is.null(src))  warning("could not get srcref")

  src
}

#' R package to make testing fun!
#'
#' Try the example below. Have a look at the references and learn more
#' from function documentation such as \code{\link{expect_that}}.
#'
#' @details Software testing is important, but, in part because
#' it is frustrating and boring, many of us avoid it.
#'
#' testthat is a new testing framework for R that is easy learn and use,
#' and integrates with your existing workflow.
#'
#' @section Options:
#' \code{testthat.use_colours}: Should the output be coloured? (Default:
#' \code{TRUE}).
#'
#' \code{testthat.summary.max_reports}: The maximum number of detailed test
#' reports printed for the summary reporter (default: 15).
#'
#' @docType package
#' @name testthat
#' @references Wickham, H (2011). testthat: Get Started with Testing.
#' \strong{The R Journal} \emph{3/1} 5-10.
#' \url{http://journal.r-project.org/archive/2011-1/RJournal_2011-1_Wickham.pdf}
#'
#' \url{https://github.com/hadley/testthat}
#'
#' \url{http://adv-r.had.co.nz/Testing.html}
#'
#' @examples
#' library(testthat)
#' a <- 9
#' expect_that(a, is_less_than(10))
#' expect_less_than(a, 10)
NULL
