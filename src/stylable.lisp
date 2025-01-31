(uiop:define-package :uncharming-tui.styles.stylable
  (:use :common-lisp :uncharming-tui.util
    :uncharming-tui.styles.styles)
  (:nicknames :ut.styles.stylable)
  (:export :stylable :init-styles :dirty-p
    :can-implement-style :stylable-id :implement-style
    :classes :styles)
  (:import-from :uncharming-tui.styles.styles :style
    :property-name :tuple-prop :style-prop :group-styles
    :apply-after :style-group-key :style-val :style-prop)
  (:import-from :uncharming-tui.styles.style-set :style-set
    :*default-styles* :copy :style-of :value-of :new))

(in-package :uncharming-tui.styles.stylable)

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
