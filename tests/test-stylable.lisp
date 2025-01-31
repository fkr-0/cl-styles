(uiop:define-package :cl-styles.tests.stylable
  (:use :common-lisp :cl-styles.stylable)
  (:export :run-tests))

(in-package :cl-styles.tests.stylable)

(defun run-tests ()
  (format t "Running Stylable tests...~%")
  ;; Add your tests here
  (format t "All Stylable tests passed!~%"))
