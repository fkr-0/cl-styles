;;; Fail-closed SB-COVER runner; always instrument production, never tests.
(in-package :cl)
(require :asdf)
(require :sb-cover)
(defvar *root* (uiop:pathname-directory-pathname *load-truename*))
(defvar *coverage-dir* (merge-pathnames #p"coverage/" *root*))
;; LCOV needs compiler line vectors; the bare quality declaration leaves them NIL.
(sb-cover:enable-coverage-logging)
(declaim (optimize (sb-cover:store-coverage-data 3)))
(handler-case
    (progn
      (when (uiop:directory-exists-p *coverage-dir*)
        (uiop:delete-directory-tree *coverage-dir* :validate t :if-does-not-exist :ignore))
      (ensure-directories-exist *coverage-dir*)
      (asdf:load-system "cl-styles" :force t)
      (asdf:load-system "cl-styles/tests")
      ;; run-all raises on failures. Never ignore its result or catch it as success.
      (funcall (find-symbol "RUN-ALL-CL-STYLES-TESTS" "CL-STYLES.TESTS"))
      (handler-bind ((error (lambda (e)
                              (format *error-output* "~&LCOV ERROR: ~A~%" e)
                              (sb-debug:print-backtrace :stream *error-output*))))
        (sb-cover:lcov-report (merge-pathnames #p"coverage.info" *coverage-dir*)))
      (sb-cover:report *coverage-dir*)
      (let ((code (uiop:wait-process
                   (uiop:launch-program
                    (list "python3" (namestring (merge-pathnames #p"scripts/coverage_gate.py" *root*))
                          "--root" (namestring *root*)
                          "--lcov" (namestring (merge-pathnames #p"coverage/coverage.info" *root*)))
                    :output *standard-output* :error-output *error-output*))))
        (unless (zerop code) (error "Coverage gate returned ~D" code)))
      (uiop:quit 0))
  (error (condition)
    (format *error-output* "~&COVERAGE FAILURE: ~A~%" condition)
    (uiop:quit 1)))
