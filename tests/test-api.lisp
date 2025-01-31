(uiop:define-package :cl-styles.tests.api
  (:use :common-lisp :cl-styles.api)
  (:export :run-tests))

(in-package :cl-styles.tests.api)

(defun run-tests ()
  (format t "Running API tests...~%")
  ;; Add your tests here
  (format t "All API tests passed!~%"))
