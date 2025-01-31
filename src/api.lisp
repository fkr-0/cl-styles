(uiop:define-package :cl-styles.api
  (:use :common-lisp)
  (:import-from :cl-styles.util :hash-table-keys)
  (:export
    ;; Classes
    :style :style-set :stylable :selector :style-rule :stylesheet

    ;; Generic functions
    :apply-style :get-style :set-style :merge-styles :selects :apply-stylesheet

    ;; Macros and functions
    :defstyle :defrule :make-style-set :make-selector))

(in-package :cl-styles.api)

;; Define base classes
(defclass style () ())
(defclass style-set () ())
(defclass stylable () ())
(defclass selector () ())
(defclass style-rule () ())
(defclass stylesheet () ())

;; Define generic functions
(defgeneric apply-style (stylable style))
(defgeneric get-style (stylable style-property))
(defgeneric set-style (stylable style-property value))
(defgeneric merge-styles (style-set1 style-set2))
(defgeneric selects (selector stylable))
(defgeneric apply-stylesheet (stylesheet stylable))

;; For macros and functions, we'll use defgeneric and provide a default method
;; that signals an error. This allows for easy overriding in implementation packages.

(defgeneric defstyle-impl (name &rest options))
(defmethod defstyle-impl (name &rest options)
  (declare (ignore name options))
  (error "defstyle not implemented"))

(defmacro defstyle (name &rest options)
  `(defstyle-impl ',name ,@options))

(defgeneric defrule-impl (selector &rest styles))
(defmethod defrule-impl (selector &rest styles)
  (declare (ignore selector styles))
  (error "defrule not implemented"))

(defmacro defrule (selector &body styles)
  `(defrule-impl ',selector ,@styles))

(defgeneric make-style-set (&rest styles))
(defmethod make-style-set (&rest styles)
  (declare (ignore styles))
  (error "make-style-set not implemented"))

(defgeneric make-selector (type &rest args))
(defmethod make-selector (type &rest args)
  (declare (ignore type args))
  (error "make-selector not implemented"))
