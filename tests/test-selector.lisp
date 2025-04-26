;;; ─── tests/test-selector.lisp ─────────────────────────────────────────
(defpackage :cl-styles.tests.selector
  (:use :cl :fiveam :cl-styles.api :cl-styles.styles
    :cl-styles.selector :cl-styles.macros)
  (:import-from :fiveam :def-suite :in-suite :test :is))
(in-package :cl-styles.tests.selector)

(def-suite :selector-tests
  :description "Tests for selectors.")

(in-suite :selector-tests)
;; Define a simple test subclass for stylable objects.

(defclass test-stylable (cl-styles.api::stylable) ()
  (:documentation "A test stylable for selector tests."))

;; Create test instances with various IDs and classes.
(defun make-test-stylables ()
  (let ((obj1 (make-instance 'test-stylable :id "obj1" :classes '("button" "primary")))
         (obj2 (make-instance 'test-stylable :id "obj2" :classes '("label")))
         (obj3 (make-instance 'test-stylable :id "obj3" :classes '("container" "primary"))))
    (list obj1 obj2 obj3)))


(test id-selector-test
  (let* ((id-sel (cl-styles.selector:id> "obj1"))
          (s (make-test-stylables))
          (r1 (first s))
          (result (cl-styles.selector::selects id-sel r1)))

    (is (eql t result) "id-selector should select obj1.")))

(test class-selector-test
  (let* ((cls-sel (cl-styles.selector:cls> "primary"))
          (results
            (mapcar (lambda (obj)
                      (not (null (cl-styles.selector::selects cls-sel obj))))
              (make-test-stylables))))
    (is (equal results '(t nil t))
      "class-selector should select obj1 and obj3.")))

(test combined-selector-test
  (let* ((id-sel (cl-styles.selector:id> "obj1"))
          (cls-sel (cl-styles.selector:cls> "button"))
          (combined (cl-styles.selector:and> id-sel cls-sel))
          (s (make-test-stylables))
          (result (cl-styles.selector::selects combined (first s))))
    (is (eql result t) "combined-selector should select obj1.")))

;; End of test-selector.lisp
