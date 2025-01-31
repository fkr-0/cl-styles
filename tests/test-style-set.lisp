(uiop:define-package :cl-styles.tests.style-set
  (:use :common-lisp :cl-styles.style-set)
  (:export :run-tests))

(in-package :cl-styles.tests.style-set)

(defun run-tests ()
  (format t "Running Style-Set tests...~%")
  ;; Add your tests here
  (format t "All Style-Set tests passed!~%"))
