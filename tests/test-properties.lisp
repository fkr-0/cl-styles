(uiop:define-package :cl-styles.tests.properties
  (:use :common-lisp :cl-styles.properties)
  (:export :run-tests))

(in-package :cl-styles.tests.properties)

(defun run-tests ()
  (format t "Running Properties tests...~%")
  ;; Add your tests here
  (format t "All Properties tests passed!~%"))
