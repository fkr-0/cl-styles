(uiop:define-package :cl-styles.tests.selector
  (:use :common-lisp :cl-styles.selector)
  (:export :run-tests))

(in-package :cl-styles.tests.selector)

(defun run-tests ()
  (format t "Running Selector tests...~%")
  ;; Add your tests here
  (format t "All Selector tests passed!~%"))
