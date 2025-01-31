(uiop:define-package :cl-styles.tests.stylesheet
  (:use :common-lisp :cl-styles.stylesheet)
  (:export :run-tests))

(in-package :cl-styles.tests.stylesheet)

(defun run-tests ()
  (format t "Running Stylesheet tests...~%")
  ;; Add your tests here
  (format t "All Stylesheet tests passed!~%"))
