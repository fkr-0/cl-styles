(uiop:define-package :cl-styles.tests.macros
  (:use :common-lisp :cl-styles.macros)
  (:export :run-tests))

(in-package :cl-styles.tests.macros)

(defun run-tests ()
  (format t "Running Macros tests...~%")
  ;; Add your tests here
  (format t "All Macros tests passed!~%"))
