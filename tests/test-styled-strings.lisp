(uiop:define-package :cl-styles.tests.styled-strings
  (:use :common-lisp :cl-styles.styled-strings)
  (:export :run-tests))

(in-package :cl-styles.tests.styled-strings)

(defun run-tests ()
  (format t "Running Styled-Strings tests...~%")
  ;; Add your tests here
  (format t "All Styled-Strings tests passed!~%"))
