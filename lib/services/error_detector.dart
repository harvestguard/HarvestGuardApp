



String errorSignInWithEmailAndPassword({required dynamic error}) {
  switch (error.code) {
    case "ERROR_INVALID_EMAIL":
      return "Your email address appears to be malformed.";
    case "ERROR_WRONG_PASSWORD":
      return "Your password is wrong.";
    case "ERROR_USER_NOT_FOUND":
      return "User with this email doesn't exist.";
    case "ERROR_USER_DISABLED":
      return "User with this email has been disabled.";
    case "ERROR_TOO_MANY_REQUESTS":
      return "Too many requests. Try again later.";
    case "ERROR_OPERATION_NOT_ALLOWED":
      return "Signing in with Email and Password is not enabled.";
    default:
      return "An undefined Error happened.";
  }
}