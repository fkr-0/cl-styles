
(defpackage :cl-styles.tests.styles
  (:use :cl :fiveam :cl-styles.api :cl-styles.styles :cl-styles.selector :cl-styles.macros)
  (:import-from :fiveam :def-suite :in-suite :test :is))
(in-package :cl-styles.tests.styles)

(def-suite :styles-tests :description "Tests for the CL-Styles system")
(in-suite :styles-tests)

(test ordered-styles-test
  "Test dependency ordering of styles"
  (let ((a (defstyle :a '(:ax :ay :az)))
         (b (defstyle :b '(:bx :by :bz)
              :decorating-after  (list :a)))
         (c (defstyle :c '(:cx :cy :cz)
              :decorating-after  :b))
         (d (defstyle :d '(:dx :dy :dz)
              :decorating-after  '(:c))))
    (is (equal (ordered-styles (list d c b a)) (list a b c d)))
    (is (equal (ordered-styles (list c a d b)) (list a b c d)))))


;; (defstyle :abcd (list :v1 :v2 :v3 :v4))
;; (defstyle :efgh (list :x1 :x2 :x3 :x4))
;; ──────────────────────────────────────────────────────────────────────────────
;; File Structure:
;;
;; 📁 tests/
;;   📄 test-styles.lisp      ;; Unit tests for the cl-styles.styles module
;;   📄 test-integration.lisp ;; Integration tests for the full library and protocol-based styling
;;
;; ──────────────────────────────────────────────────────────────────────────────

;;; File: tests/test-styles.lisp
;; Unit tests for the cl-styles.styles module using FiveAM.
;; (defpackage :cl-styles.tests.styles
;;   (:use :cl :fiveam :cl-styles.api :cl-styles.styles :cl-styles.selector :cl-styles.macros)
;;   (:import-from :fiveam :def-suite :in-suite :test :is)
;;   (:import-from :cl-styles.styles ::=? :style-p :tuple :ordered-styles)
;;   (:import-from :cl-styles.api :property :value :style :styles))
;; (in-package :cl-styles.tests.styles)

;; (def-suite :styles-tests :description "Tests for the CL-Styles system")
;; (in-suite :styles-tests)


(test property-equality-test
  (let* ((prop1 (make-instance 'cl-styles.api:property :name "color"))
          (prop2 (make-instance 'cl-styles.api:property :name "color"))
          (prop3 (make-instance 'cl-styles.api:property :name "size")))
    (is (cl-styles.styles:=? prop1 prop2)
      "Properties with identical names should be equal.")
    (is (not (cl-styles.styles:=? prop1 prop3))
      "Properties with different names should not be equal.")))

(test value-equality-test
  (let* ((val1 (make-instance 'cl-styles.api:value :value "red" :type 'string))
          (val2 (make-instance 'cl-styles.api:value :value "red" :type 'string))
          (val3 (make-instance 'cl-styles.api:value :value "blue" :type 'string)))
    (is (cl-styles.styles:=? val1 val2)
      "Values with same content should be equal.")
    (is (not (cl-styles.styles:=? val1 val3))
      "Values with different content should not be equal.")))

(test style-equality-test
  (let* ((prop (make-instance 'cl-styles.api:property :name "color"))
          (val1 (make-instance 'cl-styles.api:value :value "red" :type 'string))
          (val2 (make-instance 'cl-styles.api:value :value "red" :type 'string))
          (style1 (make-instance 'cl-styles.api:style :property prop :value val1))
          (style2 (make-instance 'cl-styles.api:style :property prop :value val2))
          (val3 (make-instance 'cl-styles.api:value :value "blue" :type 'string))
          (style3 (make-instance 'cl-styles.api:style :property prop :value val3)))
    (is (cl-styles.styles:=? style1 style2)
      "Styles with same property and value should be equal.")
    (is (not (cl-styles.styles:=? style1 style3))
      "Styles with differing values should not be equal.")))

(test style-p-test
  (let* ((prop (make-instance 'cl-styles.api:property :name "color"))
          (val (make-instance 'cl-styles.api:value :value "red" :type 'string))
          (style (make-instance 'cl-styles.api:style :property prop :value val)))
    (is (cl-styles.styles:style-p style)
      "An instance of style should return true for style-p.")
    (is (not (cl-styles.styles:style-p prop))
      "A property is not a style, so style-p should return nil.")))

(test tuple-functions-test
  (let* ((prop (make-instance 'cl-styles.api:property :name "COLOR"))
          (val (make-instance 'cl-styles.api:value :value "red" :type 'string))
          (style (make-instance 'cl-styles.api:style :property prop :value val))
          (tuple (cl-styles.styles:tuple style)))
    (is (equal (first tuple) (intern "COLOR" 'keyword))
      "The tuple's first element should be the property keyword.")
    (is (equal (second tuple) "red")
      "The tuple's second element should be the style's value.")))

(test ordered-styles-no-deps-test
  (let* ((prop1 (make-instance 'cl-styles.api:property :name "a"))
          (val1 (make-instance 'cl-styles.api:value :value 1 :type 'integer))
          (style1 (make-instance 'cl-styles.api:style :property prop1 :value val1))
          (prop2 (make-instance 'cl-styles.api:property :name "b"))
          (val2 (make-instance 'cl-styles.api:value :value 2 :type 'integer))
          (style2 (make-instance 'cl-styles.api:style :property prop2 :value val2))
          (ordered (cl-styles.styles:ordered-styles (list style1 style2))))
    (is (equal ordered (list style1 style2))
      "Ordered styles with no dependencies should preserve the original list order.")))
