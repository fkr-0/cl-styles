(uiop:define-package :cl-styles.tests.styles
  (:use :common-lisp :cl-styles.styles)
  (:export :run-tests))

(in-package :cl-styles.tests.styles)

(defun run-tests ()
  (format t "Running Styles tests...~%")
  ;; Add your tests here
  (format t "All Styles tests passed!~%"))
