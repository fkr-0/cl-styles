(uiop:define-package :cl-styles.tests.rule
  (:use :common-lisp :cl-styles.rule)
  (:export :run-tests))

(in-package :cl-styles.tests.rule)

(defun run-tests ()
  (format t "Running Rule tests...~%")
  ;; Add your tests here
  (format t "All Rule tests passed!~%"))
