(in-package :cl-styles.sheet)

(defclass stylesheet ()
  ((rules :initarg :rules :initform nil :accessor stylesheet-rules
     :documentation "List of style rules in source order.")
   (variables :initarg :variables :initform nil :accessor stylesheet-variables
     :documentation "Stylesheet variable environment.")
   (namespace :initarg :namespace :initform nil :accessor stylesheet-namespace
     :documentation "Optional namespace for the stylesheet.")
   (revision :initform 0 :reader stylesheet-revision
     :documentation "Monotonic revision for style-relevant stylesheet mutations.")))

(defun %validate-rules-with-variables (rules variables)
  "Validate static rules and all declarations after stylesheet variable resolution."
  (dolist (rule rules)
    (validate-rule rule)
    (multiple-value-bind (resolved expansions)
        (resolve-variables (rule-declarations rule) variables)
      (declare (ignore expansions))
      (cl-styles.properties:validate-declarations
       (cl-styles.properties:normalize-declarations
        (expand-shorthands resolved)))))
  rules)


(defun validate-stylesheet (sheet)
  "Validate rules and variables for SHEET and return it."
  (unless (typep sheet 'stylesheet)
    (error "Expected stylesheet, got ~S" sheet))
  (validate-variable-environment (stylesheet-variables sheet))
  (%validate-rules-with-variables (stylesheet-rules sheet)
                                  (stylesheet-variables sheet))
  sheet)

(defmethod (setf stylesheet-rules) :around (new-rules (sheet stylesheet))
  (%validate-rules-with-variables new-rules (stylesheet-variables sheet))
  (let ((old-rules (stylesheet-rules sheet)))
    (prog1 (call-next-method)
      (unless (equal old-rules new-rules)
        (incf (slot-value sheet 'revision))))))

(defmethod (setf stylesheet-variables) :around (new-variables (sheet stylesheet))
  (validate-variable-environment new-variables)
  (%validate-rules-with-variables (stylesheet-rules sheet) new-variables)
  (let ((old-variables (stylesheet-variables sheet)))
    (prog1 (call-next-method)
      (unless (equal old-variables new-variables)
        (incf (slot-value sheet 'revision))))))




(defclass style-engine ()
  ((stylesheet :initarg :stylesheet :accessor style-engine-stylesheet
     :documentation "The current stylesheet instance.")
    (patches :initform nil :accessor style-engine-patches
      :documentation "List of patches to apply.")
    (dirty :initform t :accessor style-engine-dirty
      :documentation "Flag indicating if the engine needs recompilation."))
  (:documentation "Stateful styling engine for advanced use cases like caching and batch operations.
Currently unused - the functional API (apply-stylesheet, apply-stylesheet-to-tree) is preferred.
Reserved for future optimizations like selector compilation caching or computed style caching."))

(defun make-stylesheet (&key rules variables namespace)
  "Create and validate a stylesheet instance with revision zero."
  (validate-variable-environment variables)
  (%validate-rules-with-variables rules variables)
  (make-instance 'stylesheet
                 :rules rules :variables variables :namespace namespace))


(defmacro defstylesheet (&body rules)
  "Define a stylesheet with the given rules."
  `(make-stylesheet :rules (list ,@rules)))


(defgeneric add-rule (stylesheet rule)
  (:documentation "Add a rule to the stylesheet.

WARNING: This mutates the stylesheet in-place. For functional/immutable
operations (preferred in TEA architecture), create a new stylesheet with
make-stylesheet instead."))

(defmethod add-rule ((stylesheet stylesheet) rule)
  (%validate-rules-with-variables (list rule)
                                  (stylesheet-variables stylesheet))
  (setf (slot-value stylesheet 'rules)
        (append (slot-value stylesheet 'rules) (list rule)))
  (incf (slot-value stylesheet 'revision))
  stylesheet)



(defgeneric remove-rule (stylesheet rule)
  (:documentation "Remove a rule from the stylesheet.

WARNING: This mutates the stylesheet in-place. For functional/immutable
operations (preferred in TEA architecture), create a new stylesheet with
make-stylesheet instead."))

(defmethod remove-rule ((stylesheet stylesheet) rule)
  (let* ((old (slot-value stylesheet 'rules))
         (new (remove rule old :test #'equal)))
    (unless (equal old new)
      (setf (slot-value stylesheet 'rules) new)
      (incf (slot-value stylesheet 'revision))))
  stylesheet)


;; (let ((ss (make-stylesheet :rules '((:selector ".a")))))
;;   (add-rule ss '(:selector ".b"))
;;   (remove-rule ss '(:selector ".a")))
