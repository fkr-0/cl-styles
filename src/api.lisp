(uiop:define-package :cl-styles.api
  (:use :common-lisp)
  (:import-from :cl-styles.util :hash-table-keys)
  (:export
   ;; Classes
   :style :style-set :stylable :selector :style-rule :stylesheet

   ;; Generic functions
   :apply-style :get-style :set-style :merge-styles :selects :apply-stylesheet

   ;; Macros and functions
   ;; :defstyle :defrule
   :make-style-set :make-selector))

(in-package :cl-styles.api)

(defgeneric make-style (property value)
  (:documentation "Create a new style with the given property and value."))
(defgeneric make-style-set (&rest styles))
(defmethod make-style-set (&rest styles)
  (declare (ignore styles))
  (error "make-style-set not implemented"))

(defgeneric make-selector (type &rest args))
(defmethod make-selector (type &rest args)
  (declare (ignore type args))
  (error "make-selector not implemented"))
;; Define base classes
(defclass style-component () ()
  (:documentation "Base class for style components."))

(deftype style-category ()
  '(member :layout :content :decoration :behavior))

(defclass style-metadata ()
  ((category :initarg :category
             :accessor style-category
             :type style-category
             :documentation "The category this style belongs to")
   (related-styles :initarg :related-styles
                   :accessor style-related-styles
                   :initform nil
                   :documentation "List of styles that are related to this one"))
  (:documentation "Metadata for a style including its category and relationships"))

(defclass property (style-component)
  ((name :initarg :name
         :accessor property-name
         :documentation "The name of the property."))
  (:documentation "A property represents a style property."))

(defclass value (style-component)
  ((value :initarg :value :accessor value-value)
   (type :initarg :type :accessor value-type)
   (possible-values :initarg :possible-values :accessor value-possible-values))
  (:documentation "A value represents the value of a style property."))

(defclass style ()
  ((property :initarg :property :accessor style-property)
   (value :initarg :value :accessor style-val)
   (default :initarg :default
            :accessor style-default
            :initform nil
            :documentation "The default value of the style.")
   (metadata :initarg :metadata
             :accessor style-metadata
             :initform nil
             :type (or null style-metadata)
             :documentation "Optional metadata about the style's category and relationships"))
  (:documentation "A style is a property-value pair with optional metadata."))

(defstruct style-set
  (styles (make-hash-table :test #'equal) :type hash-table) ; :documentation "Hash table mapping property symbols to style instances.")
  (order nil :type list)) ; :documentation "Optional list specifying the order of styles application."))
(defclass stylable ()
  ((sid :initarg :id
        :initform nil
        :accessor stylable-id
        :documentation "The ID of the stylable object.")
   (classes :initform 'nil
            :accessor classes
            :documentation "The classes of the stylable object.")
   (styles :accessor styles
           :type style-set
           :documentation "The styles associated with the stylable object.")
   (dirty :initform t
          :accessor dirty
          :documentation "Indicates if the stylable needs to have styles reapplied."))
  (:documentation
   "A stylable is an entity that can have styles applied to it."))

(defclass selector () () (:documentation "Base class for all selectors."))
(defclass style-rule ()
  ((selector :initarg :selector
             :accessor rule-selector
             :documentation "The selector of the rule.")
   (styles :initarg :styles
           :accessor rule-styles
           :type style-set
           :documentation "The styles associated with the rule.")
   (matched-objects :accessor matched-objects
                    :initform nil
                    :documentation "List of objects that match the selector."))
  (:documentation "A style rule consists of a selector and a set of styles."))
(defclass stylesheet ()
  ((name :initarg :name :accessor stylesheet-name)
   (rules :initarg :rules :accessor stylesheet-rules))
  (:documentation "A stylesheet is a collection of style rules."))

;; Define generic functions
(defgeneric apply-style (stylable style))
(defgeneric get-style (stylable style-property))
(defgeneric set-style (stylable style-property value))
(defgeneric merge-styles (style-set1 style-set2))
(defgeneric selects (selector stylable))
(defgeneric apply-stylesheet (stylesheet stylable))

;; For macros and functions, we'll use defgeneric and provide a default method
;; that signals an error. This allows for easy overriding in implementation packages.

;; (defgeneric defstyle-impl (name &rest options))
;; (defmethod defstyle-impl (name &rest options)
;;   (declare (ignore name options))
;;   (error "defstyle not implemented"))

;; (defmacro defstyle (name &rest options)
;;   `(defstyle-impl ',name ,@options))

;; (defgeneric defrule-impl (selector &rest styles))
;; (defmethod defrule-impl (selector &rest styles)
;;   (declare (ignore selector styles))
;;   (error "defrule not implemented"))

;; (defmacro defrule (selector &body styles)
;;   `(defrule-impl ',selector ,@styles))
