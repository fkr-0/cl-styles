;;; ─── cl-styles/selector.lisp ─────────────────────────────────────────
(uiop:define-package :cl-styles.selector (:use :common-lisp)
  (:nicknames :cl-styles.styles.selector)
  (:import-from :cl-styles.api :stylable-id :selects :selector :stylable :classes
    :parents-of)
  (:import-from :cl-styles.util :=?)
  (:export :selector :class-selector :id-selector
    :cl-class-selector :combined-selector
    :parent-selector-of :child-selector-of :cl-cls>
    :hierarchical-selector :complex-selector :cls> :id>
    :cl-class> :and> :parent-child> :selection-specificity))
(in-package :cl-styles.selector)

(defgeneric selects (selector target)
  (:documentation
    "Return T if the given selector selects the given target, NIL otherwise."))

(defmethod print-object ((selector selector) stream)
  "Print a representation of the selector."
  (format stream "<~a:>" (type-of selector)))

(defclass class-selector (selector)
  ((class-name :initarg :class-name
     :accessor class-name-of
     :documentation "The name of the class to select."))
  (:documentation "Selects elements based on class name."))

(defmethod print-object ((selector class-selector) stream)
  "Print a representation of the class-selector."
  (format stream "<~a: ~a>" (type-of selector) (class-name-of selector)))

(defclass id-selector (selector)
  ((id :initarg :id
     :accessor id-of
     :documentation "The ID of the element to select."))
  (:documentation "Selects elements based on ID."))

(defmethod print-object ((selector id-selector) stream)
  "Print a representation of the id-selector."
  (format stream "<~a: ~a>" (type-of selector) (id-of selector)))

(defclass cl-class-selector (selector)
  ((cl-class-name :initarg :cl-class-name
     :accessor cl-class-name-of
     :documentation "The name of the Common Lisp class to select."))
  (:documentation "Selects elements based on Common Lisp class name."))

(defmethod print-object ((selector cl-class-selector) stream)
  "Print a representation of the cl-class-selector."
  (format stream "<~a: ~a>" (type-of selector) (cl-class-name-of selector)))

(defclass combined-selector (selector)
  ((sub-selectors :initarg :sub-selectors
     :accessor sub-selectors-of
     :documentation "A list of selectors to be combined (logical AND)."))
  (:documentation "Combines multiple selectors logically."))

(defclass hierarchical-selector (selector)
  ((parent-selector :initarg :parent-selector
     :accessor parent-selector-of
     :documentation "The parent selector in the relationship.")
    (child-selector :initarg :child-selector
      :accessor child-selector-of
      :documentation "The child selector in the relationship."))
  (:documentation
    "Represents a hierarchical relationship between selectors (parent-child)."))

(defclass complex-selector (selector)
  ((child-selector :initarg :child-selector
     :accessor child-selector-of
     :documentation "The child selector that further specifies the target.")
    (relationship-type :initarg :relationship-type
      :accessor relationship-type-of
      :documentation "The type of relationship (e.g., parent, ancestor)."))
  (:documentation
    "Represents a complex selector with a hierarchical relationship."))

(defmacro cls> (name)
  "Create a class-selector for the given class name."
  `(make-instance 'class-selector :class-name ,name))

(defmacro id> (name)
  "Create an id-selector for the given ID."
  `(make-instance 'id-selector :id ,name))

(defmacro cl-cls> (name)
  "Create a cl-class-selector for the given Common Lisp class name."
  `(make-instance 'cl-class-selector :cl-class-name ,name))

(defmacro and> (&rest selectors)
  "Create a combined-selector that logically ANDs the given selectors."
  `(make-instance 'combined-selector :sub-selectors (list ,@selectors)))

(defmacro parent-child> (parent child)
  "Create a hierarchical-selector representing a parent-child relationship."
  `(make-instance 'hierarchical-selector
     :parent-selector ,parent
     :child-selector ,child))

(defmethod (setf parent-selector-of) :before (new-value (selector hierarchical-selector))
  "Set the parent selector of a hierarchical-selector."
  (unless (typep new-value 'selector)
    (error "Parent selector must be a selector.")))

(defmethod (setf child-selector-of) :before (new-value (selector hierarchical-selector))
  "Set the child selector of a hierarchical-selector."
  (unless (typep new-value 'selector)
    (error "Child selector must be a selector.")))

(defmethod selects (selector  (target null) )nil)

(defmethod selects ((selector class-selector) (target stylable))
  "Return T if the target has the class specified by the selector."
  (member (class-name-of selector) (classes target) :test #'string-equal))

(defmethod selects ((selector id-selector) (target stylable))
  "Return T if the target has the ID specified by the selector."
  (string-equal (id-of selector) (stylable-id target)))

(defmethod selects ((selector cl-class-selector) (target stylable))
  "Return T if the target is of the type specified by the selector."
  (typep target (find-class (cl-class-name-of selector) nil)))

(defmethod selects ((selector combined-selector) (target stylable))
  "Return T if all sub-selectors match the target."
  (every (lambda (sub-sel) (selects sub-sel target))
    (sub-selectors-of selector)))

(defmethod selects ((selector hierarchical-selector) (target stylable))
  "Return T if the parent and child selectors match the target."
  (and (selects (parent-selector-of selector) (first (parents-of target)))
    (selects (child-selector-of selector) target)))

(defmethod selection-specificity ((selector selector))
  "Return a number representing the specificity of the selector."
  (etypecase selector
    (class-selector 100)
    (id-selector 1000)
    (cl-class-selector 1)
    (combined-selector
      (+ 1000
        (reduce #'+
          (mapcar #'selection-specificity (sub-selectors-of selector))
          :initial-value 0)))
    (hierarchical-selector
      (+ 1000 (selection-specificity (parent-selector-of selector))
        (selection-specificity (child-selector-of selector))))))

(defmethod =? ((selector selector) (other selector))
  "Return T if the two selectors are equal, NIL otherwise."
  (and (typep other (class-of selector))
    (etypecase selector
      (class-selector
        (string= (class-name-of selector) (class-name-of other)))
      (id-selector (string= (id-of selector) (id-of other)))
      (cl-class-selector
        (string= (cl-class-name-of selector) (cl-class-name-of other)))
      (combined-selector
        (every #'=? (sub-selectors-of selector) (sub-selectors-of other)))
      (hierarchical-selector
        (and (=? (parent-selector-of selector) (parent-selector-of other))
          (=? (child-selector-of selector) (child-selector-of other)))))))
;; End of selector.lisp
