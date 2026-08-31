(in-package :cl-styles.adapters)

(defun %raw-rgb-triple-p (value)
  (and (listp value)
       (= (length value) 3)
       (every (lambda (channel)
                (and (integerp channel) (<= 0 channel 255)))
              value)))

(defun %canonical-tui-color (value)
  (if (%raw-rgb-triple-p value)
      (apply #'rgb value)
      value))

(defun normalize-tui-declarations (plist)
  "Normalize ElmTUI compatibility declarations without weakening core validation.

Legacy TUI spellings are translated once at style ingress.  The reusable
property engine can therefore stay strict while render/layout code receives a
canonical declaration vocabulary."
  (let* ((normalized (normalize-declarations plist))
         (box-present-p (member :box normalized :test #'eql))
         (box (and box-present-p (getf normalized :box)))
         (border-present-p (member :border normalized :test #'eql))
         (border-style-present-p (member :border-style normalized :test #'eql))
         (out (copy-list normalized))
         (attrs (copy-list (getf out :attributes))))
    (labels ((move-when-absent (legacy canonical)
               (when (member legacy out :test #'eql)
                 (unless (member canonical out :test #'eql)
                   (setf (getf out canonical) (getf out legacy)))
                 (remf out legacy))))
      (move-when-absent :direction :flex-direction)
      (move-when-absent :spacing :gap)
      (move-when-absent :justify :justify-content))
    (dolist (attribute '(:bold :italic :underline :inverse :faint
                         :blink :strike :invisible))
      (when (member attribute out :test #'eql)
        (unless (member (getf out attribute) '(nil :nil) :test #'eql)
          (pushnew attribute attrs :test #'eql))
        (remf out attribute)))
    (when attrs
      (setf (getf out :attributes) (nreverse attrs)))
    (dolist (property '(:color :background-color :border-color
                        :border-top-color :border-right-color
                        :border-bottom-color :border-left-color))
      (when (member property out :test #'eql)
        (setf (getf out property)
              (%canonical-tui-color (getf out property)))))
    (remf out :box)
    (when (member (getf out :border) '(t :t) :test #'eql)
      (setf (getf out :border) 1))
    (when box-present-p
      (unless border-present-p
        (setf (getf out :border) 1))
      (unless border-style-present-p
        (setf (getf out :border-style)
              (case box
                (:single :solid)
                (:ascii :ascii)
                (:double :double)
                (:none :none)
                (:solid :solid)
                (otherwise box)))))
    out))

(defun normalize-tui-style-plist (plist)
  "Extract terminal colors/attributes from PLIST without rebuilding declarations.

This function sits on the per-node render hot path.  Declaration compatibility
normalization belongs at style ingress in NORMALIZE-TUI-DECLARATIONS; rendering
only needs a small alias-aware projection."
  (let ((fg (or (getf plist :color)
                (getf plist :fg-color)
                (getf plist :fg)
                (getf plist :foreground-color)))
        (bg (or (getf plist :background-color)
                (getf plist :bg-color)
                (getf plist :bg)
                (getf plist :background)))
        (attrs (copy-list (or (getf plist :attributes)
                              (getf plist :attrs)))))
    (dolist (attribute '(:bold :italic :underline :inverse :faint
                         :blink :strike :invisible))
      (when (getf plist attribute)
        (pushnew attribute attrs :test #'eql)))
    (list :fg-color fg
          :bg-color bg
          :attrs attrs)))
