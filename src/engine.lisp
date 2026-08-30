(in-package :cl-styles.engine)

(defstruct style-patch path computed)

(defparameter *cascade-semantics-revision* 1)

(defstruct style-revision cascade stylesheet)

(defstruct declaration-trace
  property value origin selector specificity source-order source-declarations
  variable-expansions status)

(defstruct computed-style-result style revision trace diagnostics)


(defun %plist-merge (a b)
  "Non Destructively merge plist B onto A (B wins).

Returns merged list, a is not modified.

Example:
 (let ((a '(:color :red :width 10))
       (b '(:width 20 :height 30)))
   (list (%plist-merge a b) a b))
  => ((:COLOR :RED :WIDTH 20 :HEIGHT 30)
(:COLOR :RED :WIDTH 10)
(:WIDTH 20 :HEIGHT 30))"
   (loop for (k v) on b by #'cddr
         do (setf (getf a k) v))
   (copy-list a))
;; (let* ((a '(:color :red :width 10))
;;        (b '(:width 20 :height 30))
;;        (x (list a b))
;;        (y (%plist-merge a b)))
;;    (list y a b x))

;; (defun %normalize-decls (plist sheet)
;;   "Normalize and validate declarations in PLIST, using SHEET for variable resolution.
;; Returns normalized and validated plist.
;; Arguments:
;;  PLIST  A property list of declarations.
;;  SHEET  (optional) A cl-styles.sheet:stylesheet object for variable resolution.
;; Example:
;;  (let ((sheet (cl-styles.sheet:make-stylesheet
;;                 :variables '((\"--main-color\" . :blue)))))
;;    (%normalize-decls '(:color (var \"--main-color\") :padding 10 :margin (5 10)) sheet))
;;  => (:COLOR :BLUE :PADDING 10 :MARGIN (5 10))"
;;   (let* ((expanded (cl-styles.rule:expand-shorthands plist))
;;          (vars (and sheet (cl-styles.sheet:stylesheet-variables sheet)))
;;          (resolved (if vars (cl-styles.tokens:resolve-variables expanded vars) expanded))
;;          (normalized (cl-styles.properties:normalize-declarations resolved)))
;;     (cl-styles.properties:validate-declarations normalized)))
(defun %normalize-decls (plist &optional sheet)
  "Resolve variables, expand shorthands, normalize aliases, and validate PLIST.
Returns the normalized plist and variable-expansion records."
  (let ((vars (and sheet (cl-styles.sheet:stylesheet-variables sheet))))
    (multiple-value-bind (resolved expansions)
        (cl-styles.tokens:resolve-variables (or plist nil) vars)
      (let* ((expanded (cl-styles.rule:expand-shorthands resolved))
             (normalized (cl-styles.properties:normalize-declarations expanded)))
        (values (cl-styles.properties:validate-declarations normalized)
                expansions)))))

;; (let ((sheet (cl-styles.sheet:make-stylesheet
;;                 :variables '(("--font-family" . "Arial")
;;                              ("--main-color" . :blue)))))
;;    (%normalize-decls (list :color (var "--main-color") :padding 10 :margin '(5 10) :font-family (var "--font-family")) sheet))
;; (let ((sheet (cl-styles.sheet:make-stylesheet
;;                 :variables '(("--main-color" . :blue)))))
;;    (%normalize-decls (list :color (var "--main-color") :padding 10 :margin '(5 10)) sheet))


(defun match-rules (obj sheet)
  (loop for r in (or (and sheet (cl-styles.sheet:stylesheet-rules sheet)) )
        for sel = (cl-styles.rule:rule-selector r)
        when (cl-styles.selector:match-selector-p sel obj)
          collect (cons r (or (cl-styles.rule:rule-specificity r)
                              (cl-styles.selector:selector-specificity sel)))))



(defun %spec< (a b)
  "Ascending compare for specificity triples (a b c)."
  (or (< (first a) (first b))
      (and (= (first a) (first b)) (< (second a) (second b)))
      (and (= (first a) (first b)) (= (second a) (second b)) (< (third a) (third b)))))



(defparameter *inheritable-keys* '(:color :font-size :font-family :font-weight))

(defun %plist-present-p (plist key)
  (loop for (candidate value) on plist by #'cddr
        when (eql candidate key) do (return t)
        finally (return nil)))


(defun %inherit (parent child)
  "Inherit configured properties from PARENT only when CHILD has no declaration."
  (let ((out (copy-list child)))
    (dolist (key *inheritable-keys* out)
      (when (and (%plist-present-p parent key)
                 (not (%plist-present-p out key)))
        (setf (getf out key) (getf parent key))))))


(defun %matched-source-orders (rules sheet)
  "Return stylesheet source indexes corresponding to matched RULES in order."
  (if (null sheet)
      (loop for index from 0 below (length rules) collect index)
      (let ((remaining rules)
            (orders nil))
        (loop for candidate in (cl-styles.sheet:stylesheet-rules sheet)
              for index from 0
              while remaining
              when (eq candidate (car (car remaining)))
                do (push index orders)
                   (setf remaining (cdr remaining)))
        (when remaining
          (error "Matched rule list is not an ordered subsequence of stylesheet rules: ~S"
                 remaining))
        (nreverse orders))))

(defun %compute-style-core (obj rules inherit-from sheet trace-p)
  (let ((style nil)
        (trace nil)
        (diagnostics nil)
        (winners (and trace-p (make-hash-table :test #'eql))))
    (labels ((remember-diagnostics (expansions)
               (when trace-p
                 (dolist (expansion expansions)
                   (when (variable-expansion-fallback-used-p expansion)
                     (push expansion diagnostics)))))
             (apply-source (declarations origin
                            &key selector specificity source-order
                              source-declarations variable-expansions)
               (remember-diagnostics variable-expansions)
               (loop for (property value) on declarations by #'cddr
                     do (when trace-p
                          (let ((previous (gethash property winners)))
                            (when previous
                              (setf (declaration-trace-status previous) :overridden)))
                          (let ((entry (make-declaration-trace
                                        :property property :value value :origin origin
                                        :selector selector :specificity specificity
                                        :source-order source-order
                                        :source-declarations (copy-list source-declarations)
                                        :variable-expansions variable-expansions
                                        :status :winner)))
                            (setf (gethash property winners) entry)
                            (push entry trace)))
                        (setf (getf style property) value))))
      (multiple-value-bind (defaults default-expansions)
          (%normalize-decls (cl-styles.properties:property-defaults) sheet)
        (apply-source defaults :default
                      :source-declarations defaults
                      :variable-expansions default-expansions))
      (when inherit-from
        (let ((inherited nil))
          (dolist (key *inheritable-keys*)
            (when (%plist-present-p inherit-from key)
              (setf (getf inherited key) (getf inherit-from key))))
          (apply-source inherited :inherited :source-declarations inherited)))
      (dolist (item
               (stable-sort
                (loop for pair in rules
                      for source-order in (%matched-source-orders rules sheet)
                      collect (list source-order pair))
                #'%spec< :key (lambda (entry) (cdr (second entry)))))
        (destructuring-bind (source-order pair) item
          (let* ((rule (car pair))
                 (specificity (cdr pair))
                 (raw (cl-styles.rule:rule-declarations rule)))
            (multiple-value-bind (declarations expansions)
                (%normalize-decls raw sheet)
              (apply-source declarations :rule
                            :selector (cl-styles.rule:rule-selector rule)
                            :specificity specificity
                            :source-order source-order
                            :source-declarations raw
                            :variable-expansions expansions)))))
      (let ((inline (cl-styles.protocols:stylable-inline-style obj)))
        (when inline
          (multiple-value-bind (declarations expansions)
              (%normalize-decls inline sheet)
            (apply-source declarations :inline
                          :specificity :inline
                          :source-order (length rules)
                          :source-declarations inline
                          :variable-expansions expansions))))
      (values style (and trace-p (nreverse trace))
              (and trace-p (nreverse diagnostics))))))

(defun compute-style (obj rules &key (inherit-from nil) (sheet nil))
  "Compute OBJ style using defaults < inheritance < rules < inline precedence.
Rules sort by specificity and retain source order for ties; later tied rules win."
  (nth-value 0 (%compute-style-core obj rules inherit-from sheet nil)))

(defun compute-style-result (obj rules &key (inherit-from nil) (sheet nil) (trace nil))
  "Return a first-class computed style result with an explicit cascade revision."
  (multiple-value-bind (style declarations diagnostics)
      (%compute-style-core obj rules inherit-from sheet trace)
    (make-computed-style-result
     :style style
     :revision (make-style-revision
                :cascade *cascade-semantics-revision*
                :stylesheet (and sheet (cl-styles.sheet:stylesheet-revision sheet)))
     :trace declarations
     :diagnostics diagnostics)))

(defun %compute-parent-style (obj sheet)
  (let ((parent (handler-case (cl-styles.protocols:stylable-parent obj)
                  (unbound-slot () nil))))
    (when parent
      (compute-style parent (match-rules parent sheet)
                     :inherit-from (%compute-parent-style parent sheet)
                     :sheet sheet))))


(defun explain-style (obj sheet &key (inherit-from nil inherit-from-p))
  "Explain OBJ's cascade without mutating it.
The trace marks every candidate :WINNER or :OVERRIDDEN and records origin,
specificity, source order, source declarations, and variable expansion."
  (compute-style-result
   obj (match-rules obj sheet)
   :inherit-from (if inherit-from-p inherit-from (%compute-parent-style obj sheet))
   :sheet sheet :trace t))



(defun inherit-properties (parent child)
  (declare (ignore parent child))
  ;; Placeholder: implement CSS inheritance as needed
  nil)

(defun %apply-node (node sheet return &key (inherit-from nil))
  ;; (format *trace-output* "~&[apply-node] Applying to ~a" (cl-styles.protocols:stylable-id node))
  (let* ((pairs (match-rules node sheet))
         (style (compute-style node pairs :inherit-from inherit-from :sheet sheet))
         (res (cl-styles.protocols:set-computed-style node style)))
    ;; (format *trace-output* "~&[apply-node] Computed style for ~a: ~a" (cl-styles.protocols:stylable-id node) style)
    (ecase return
      (:patches (if (typep res 'style-patch)
                    (list res)
                    (list (make-style-patch :path (list :by-key (cl-styles.protocols:stylable-key node))
                                            :computed style))))
      (:objects (list res)))))

(defun apply-stylesheet (sheet objects &key (return :patches))
  "Apply SHEET to a flat list of OBJECTS, returning either :patches or :objects.

If :patches, return a list of style-patch structs with the path to the object and its computed style.
If :objects, return a list of the objects themselves with their computed styles set.

Objects must implement the cl-styles.protocols interface.

Arguments:
 SHEET    A cl-styles.sheet:stylesheet object.
 OBJECTS  A list of objects implementing cl-styles.protocols.
 RETURN   Either :patches (default) or :objects.

Returns:
 A list of style-patch structs or objects with computed styles set.

Example:
 (apply-stylesheet (make-stylesheet :rules ((defrule (type> :button) :color :red)))
                   (list (make-object :id :btn1 :type :button)
                        (make-object :id :lbl1 :type :label))
                   :return :patches)
 => (#<STYLE-PATCH path (:BY-KEY :BTN1) computed (:COLOR :RED)
      #<STYLE-PATCH path (:BY-KEY :LBL1) computed NIL)
or if :return :objects:
  => (#<OBJECT id :BTN1 type :BUTTON computed (:COLOR :RED)>
      #<OBJECT id :LBL1 type :LABEL computed NIL>)"
  (apply #'append (mapcar (lambda (o) (%apply-node o sheet return)) objects)))

(defun apply-stylesheet-to-tree (root sheet &key (return :patches) cache previous-signature)
  "Apply SHEET to ROOT by full recomputation.
CACHE and PREVIOUS-SIGNATURE are accepted for source compatibility but ignored;
revision-safe caching is a separate contract and stale cached style is never reused."
  (declare (ignore cache previous-signature))
  (labels ((walk (node inherit-style)
             (let* ((self-patches (%apply-node node sheet return
                                               :inherit-from inherit-style))
                    (children (or (cl-styles.protocols:stylable-children node) nil))
                    (computed-here (cl-styles.protocols:get-computed-style node))
                    (child-patches (mapcan (lambda (child)
                                             (walk child computed-here))
                                           children)))
               (append self-patches child-patches))))
    (walk root nil)))


;; (cl-styles.rule:defrule (cl-styles.selector:type> :text) :color :red)
