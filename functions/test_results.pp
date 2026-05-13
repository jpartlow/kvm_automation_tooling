# This function is used in do_until loops to log errors from a result set
# while returning the overall status of the result for the loop. It's
# a workaround for the fact that we can't get the final result set
# outside of the loop.
#
# @param message A string to prefix any error messages with.
# @param results A ResultSet from a task or apply that we want to log
#   errors from and return the overall status of.
# @return Boolean true if none of the results had errors.
function kvm_automation_tooling::test_results(
  String $message,
  ResultSet $results,
) >> Boolean {
  $results.error_set().each |$result| {
    log::warn("${message} on ${result.target()}: ${result.message()}")
  }
  $results.ok()
}
