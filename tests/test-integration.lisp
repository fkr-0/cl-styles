
;;; ──────────────────────────────────────────────────────────────────────────────
;;; File: tests/test-integration.lisp
;; Integration tests for the full cl-styles library and discussion on decoupling
;; from a dedicated 'stylable' class.
;;
;; Discussion:
;;   Currently, our library assumes that objects to be styled inherit from the
;;   'stylable' class. An alternative idiomatic approach in Common Lisp is to define
;;   a protocol (using generics in cl-styles.api) that demands certain behaviours:
;;     - (styles obj): should return the style-set associated with the object.
;;     - (apply-style obj style): should apply a given style to the object.
;;
;;   With appropriate generic implementations, any object that satisfies this protocol
;;   (even if not inheriting from a common base class) can be styled. This promotes
;;   flexibility and decouples styling behaviour from class hierarchies.
;;
;;   Below, we define a minimal, plain object 'minimal-stylable' that does not inherit
;;   from a dedicated stylable class, and we provide the required generic methods.
;; ──────────────────────────────────────────────────────────────────────────────

(defpackage :cl-styles.tests.integration
  (:use :cl :fiveam :cl-styles.api :cl-styles.styles :cl-styles.selector :cl-styles.macros)
  (:import-from :fiveam :def-suite :in-suite :test :is)
  (:import-from :cl-styles.api :styles :apply-style :make-style)
  (:import-from :cl-styles.style-set :copy))
(in-package :cl-styles.tests.integration)

;; Define a minimal object without using the stylable class.
(defstruct minimal-stylable
  styles)  ; Plain structure with a 'styles' slot.

;; Provide minimal generic implementations for our styling protocol.
(defmethod cl-styles.api:styles ((obj minimal-stylable))
  "Return the style-set of the minimal-stylable object."
  (minimal-stylable-styles obj))

;; For testing, our apply-style simply merges the style into the object's style-set.
(defmethod cl-styles.api:apply-style ((obj minimal-stylable) (st cl-styles.api:style))
  (let* ((prop (cl-styles.styles:tuple-prop st))
          (ss (minimal-stylable-styles obj)))
    (setf (gethash prop (slot-value ss 'styles)) st)
    obj))

;; Helper to create a minimal-stylable with default styles.
;; (defun make-minimal-stylable ()
;;   (make-instance 'minimal-stylable :styles (cl-styles.style-set::copy cl-styles.style-set:*default-styles*)))

(def-suite :integration-tests
  :description "Integration tests for the full cl-styles library using protocol-based styling.")

(in-suite :integration-tests)

;; (test default-style-set-integration-test
;;   (let ((obj (make-minimal-stylable)))
;;     (is (not (null (cl-styles.api:styles obj)))
;;       "Minimal stylable should have its default styles initialized.")))

(test stylesheet-application-integration-test
  (let* ((obj (make-minimal-stylable))
          ;; Create a style rule that sets :fg-color to "green" for objects matching the selector.
          (rule
            (make-instance 'cl-styles.api::style-rule
              :selector (cl-styles.selector:cls> "test")
              :styles (cl-styles.style-set:new 'cl-styles.api:style-set
                        :styles
                        (list
                          (make-style :fg-color :green)))))
          (sheet (make-instance 'cl-styles.api:stylesheet :name "IntegrationSheet" :rules (list rule))))
    ;; Monkey-patch the selector method for minimal-stylable to simulate that every minimal-stylable
    ;; satisfies the "test" class condition.
    (defmethod cl-styles.selector::selects ((selector cl-styles.selector:class-selector) (target minimal-stylable))
      t)
    (let ((queried (cl-styles.stylesheet:query-style-sheet sheet obj)))
      (is (eql (cl-styles.style-set:value-of queried :fg-color) :green)
        "Stylesheet query should yield 'fg-color' set to \"green\" for the minimal stylable."))))
