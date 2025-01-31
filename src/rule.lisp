(uiop:define-package :uncharming-tui.styles.rule (:nicknames :ut.styles.rule)
  (:use :common-lisp)
  (:import-from :ut.util :hash-table-keys)
  (:import-from :ut.styles.style-set :style-set :styles-list
    :new :style-set-styles :style-of :merge-styles!)
  (:import-from :ut.styles.selector :selector)
  (:import-from :ut.styles.styles :tuple-prop :style-p
    :style-property :value-value :style :style-val
    :group-styles :make-default-styling :valid-style-value-p
    :apply-after :ordered-styles :make-style)
  (:export :style-rule :new :defrule))

(in-package :uncharming-tui.styles.rule)

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

(defmethod print-object ((rule style-rule) stream)
  (format stream "#<StyleRule ~a: ~a>" (rule-selector rule)
    (styles-list (rule-styles rule))))

(defmethod style-rule-valid ((s style-rule))
  "Return T if the style rule is valid, NIL otherwise."
  (and (rule-selector s)
    (> (hash-table-count (style-set-styles (rule-styles s))) 0)))

(defmethod new ((class (eql 'style-rule)) &key selector styles)
  "Create a new style rule."
  (let ((rule (make-instance 'style-rule :selector selector :styles styles)))
    (when (style-rule-valid rule)
      rule)))

(defmacro defrule (selector &body styles)
  "Macro to define a style rule.

Arguments:
  selector: The selector for the rule (instance of a selector subclass).
  styles: The styles to apply (as property-value pairs).

Example:
  (defrule (cls> \"button\") (:bg-color :red))"
  `(make-instance 'style-rule
     :selector ,selector
     :styles (new 'style-set :styles ',styles)))
