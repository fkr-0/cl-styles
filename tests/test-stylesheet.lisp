;;; ─── tests/test-stylesheet.lisp ───────────────────────────────────────
(defpackage :cl-styles.tests.stylesheet
  (:use :cl :fiveam
    :cl-styles.api
    :cl-styles.styles
    :cl-styles.stylesheet
    :cl-styles.selector
    :cl-styles.macros)
  (:export #:run-tests)
  )
(in-package :cl-styles.tests.stylesheet)


(def-suite :stylesheet-tests
  :description "Tests for stylesheet functionality.")

(in-suite :stylesheet-tests)



;; Define a test subclass for stylable objects.
(defclass test-stylable (cl-styles.stylable::stylable) ()
  (:documentation "A test stylable for stylesheet tests."))

(defparameter *test-stylable*
  (make-instance 'test-stylable :id "test1" :classes '("button")))

;; For testing, we create a dummy style rule.
(defclass test-style-rule (cl-styles.api:style-rule)
  ((selector :initarg :selector :accessor rule-selector)
    (styles :initarg :styles :accessor rule-styles))
  (:documentation "A test style rule."))
(defparameter *test-rule* nil)
(let* ((selector (cl-styles.selector:cls> "button"))
        (style-set (cl-styles.api::make-style-set))
        (style (cl-styles.api::make-style :bg-color :blue))
        (dummy-rule (make-instance 'test-style-rule :selector selector :styles style-set)))
  (setf (gethash :bg-color (slot-value style-set 'cl-styles.api::styles)) style)
  (defparameter *test-rule* dummy-rule))
;; Create a stylesheet containing the test rule.
(defparameter *test-stylesheet*
  (make-instance 'cl-styles.api:stylesheet :name "TestSheet" :rules (list *test-rule*)))
(test query-stylesheet-test
  (let ((queried-styles (cl-styles.stylesheet:query-style-sheet *test-stylesheet* *test-stylable*)))
    (is (eql (cl-styles.style-set:value-of queried-styles :bg-color) :blue)
      "Stylesheet should provide bg-color blue.")))

(fiveam:run! 'stylesheet-tests)
;; End of test-stylesheet.lisp
