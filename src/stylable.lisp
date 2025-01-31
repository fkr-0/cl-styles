(uiop:define-package :cl-styles.stylable
  (:use :common-lisp
   :cl-styles.styles)
  (:nicknames :styles.stylable)
  (:export :init-styles :dirty-p
           :can-implement-style :implement-style :classes)
  (:import-from :cl-styles.api :style :property :styles :stylable-id
   :style-prop :property-name :style-val :style-property :stylable :styles
   :selector :style-set :apply-style :select-stylables :stylable)
  (:import-from :cl-styles.styles  :group-styles :apply-after :tuple-prop
                :style-group-key )
  (:import-from :cl-styles.style-set
   :*default-styles* :copy :style-of :value-of :new))

(in-package :cl-styles.stylable)



(defgeneric init-styles (obj)
  (:method ((obj stylable))
    "Initialize the styles for the stylable object."
    (setf (styles obj) (copy *default-styles*)))
  (:documentation
   "Initialize the styles for an object. Subclasses can provide additional styles."))

(defmethod initialize-instance :after
    ((s stylable) &key id classes &allow-other-keys)
  "After method for initializing a stylable object."
  (init-styles s)
  (unless (stylable-id s)
    (setf (stylable-id s) (or id (gensym))))
  (when classes
    (setf (classes s) classes)))

(defmethod dirty-p ((stylable stylable))
  "Return T if the stylable is dirty (needs styles reapplied), NIL otherwise."
  (dirty stylable))

(defgeneric implement-style (stylable style value)
  (:documentation "Attempt to implement the given style in the stylable.
The stylable must have a method defined for each possible style property.
If the style cannot be implemented, an error is signaled."))

(defmethod implement-style ((stylable stylable) (style property) value)
  "Default implementation that signals an error indicating the style is unimplemented."
  (error "Style ~A is unimplemented in stylable ~A." (property-name style)
         (type-of stylable)))

(defgeneric can-implement-style (stylable style)
  (:method ((stylable stylable) style) nil)
  (:documentation
   "Return T if the stylable can implement the given style, NIL otherwise."))

(defmethod can-implement-style ((stylable stylable) (style property))
  "Determines if the stylable can implement the given style."
  (handler-case (progn (implement-style stylable style nil) t)
    (error ()
      nil)))
(defmethod apply-style ((stylable stylable) (style style))
  "Apply a style to a single stylable object."
  (setf (gethash (style-property style) (styles stylable))
        (value-value (style-val style))))

(defmethod apply-style ((stylables list) (style style))
  "Apply a style to all matching stylables in the list."
  (dolist (stylable (select-stylables (style-selector style) stylables))
    (apply-style stylable style)))
(defmethod select-stylables ((selector selector) (stylables list))
  "Select stylables matching the given selector."
  (remove-if-not (lambda (stylable)
                   (string= (stylable-id stylable) (sel-name selector)))
                 stylables))

(defmethod select-stylables ((selector selector) (stylable stylable))
  "Check if a single stylable matches the selector."
  (if (string= (stylable-id stylable) (sel-name selector))
      (list stylable)
      nil))
