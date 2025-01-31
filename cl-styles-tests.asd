(in-package :asdf-user)


(defsystem "cl-styles-tests"
  :description "Tests for the cl-styles library."
  :author "Your Name <your.email@example.com>"
  :license "MIT"
  :version "0.1.0"
  :depends-on (cl-styles fiveam)

  :serial t
  :components ((:file "tests/test-api")
               (:file "tests/test-macros")
               (:file "tests/test-properties")
               (:file "tests/test-rule")
               (:file "tests/test-selector")
               (:file "tests/test-stylable")
               (:file "tests/test-style-set")
               (:file "tests/test-styled-strings")
               (:file "tests/test-styles")
               (:file "tests/test-stylesheet")))
