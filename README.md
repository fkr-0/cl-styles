# cl-styles

[![CI](https://github.com/fkr-0/cl-styles/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/fkr-0/cl-styles/actions/workflows/ci.yml)
[![Measured coverage](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Ffkr-0%2Fcl-styles%2Fcoverage-data%2Fcoverage.json)](https://github.com/fkr-0/cl-styles/actions/workflows/ci.yml)

Coverage is calculated from instrumented production sources on CI; the badge is published only after a passing main-branch run. The current measured release floor is 60% (SBCL 2.6.2 local measurement: 60.42%); the improvement target is at least 85%.

A CSS-like styling engine for Common Lisp, designed for TUI (Terminal User Interface) applications and other hierarchical object structures. cl-styles provides a flexible, declarative way to style objects using familiar CSS concepts like selectors, rules, inheritance, and variables.

## Release status

The current in-tree candidate version is **0.2.0** for both `cl-styles` and
`cl-styles/tests`. This is release-candidate metadata only: the library has a [public GitHub source repository](https://github.com/fkr-0/cl-styles), but has not been published to Quicklisp, Ultralisp, or a public CLPM index. A v0.2.0 release tag is not claimed.

The qualified implementation boundary is SBCL on the repository's POSIX/Linux
CLPM environment. Other Common Lisp implementations and non-POSIX platforms
have not yet been qualified. `cl-styles.api` is the public convenience package;
the focused `cl-styles.*` packages expose selector, rule, sheet, engine,
property, token, and protocol contracts.

## Features

- **CSS-like selectors**: Type, ID, class, attribute, and pseudo-class selectors
- **Selector combinators**: Descendant, child, logical composition, negation, and `:has` relationships
- **Property inheritance**: Automatic inheritance of inheritable properties
- **CSS variables**: Recursive references with explicit fallback plus typed missing/cycle diagnostics
- **Deterministic cascade**: Specificity, source order, inheritance, inline priority, and per-source shorthand expansion
- **Flexible object protocol**: Works with any object implementing the styling protocol
- **Correctness-first recomputation**: No stale style cache is reused; revision-safe caching is a separate optimization contract
- **Comprehensive test suite**: 190 current assertions covering selectors, properties, cascade tracing, inheritance, variables, flex/grid declarations, and edge cases

## Installation

Add cl-styles to your project dependencies. The library requires:
- Common Lisp implementation (tested with SBCL)
- alexandria
- uiop

Using the local CLPM bundle from this directory:
```bash
clpm bundle install
clpm bundle exec --with-client sbcl -- \
  --noinform --non-interactive \
  --eval '(require :asdf)' \
  --eval '(asdf:load-system "cl-styles")'
```

Using an ASDF/Quicklisp local project (not registry publication):
```lisp
;; Add to your system dependencies
:depends-on (#:cl-styles #:other-deps)
```

## Quick Start

```lisp
(use-package :cl-styles.api)

;; Create a stylesheet with rules
(defvar *my-theme* 
  (make-stylesheet
    :rules (list
      ;; Style all buttons
      (defrule (type> :button)
        :background :blue
        :color :white
        :padding 8)
      
      ;; Style primary buttons  
      (defrule (cls> "primary")
        :background :red
        :font-weight :bold)
      
      ;; Style specific button
      (defrule (id> :save-btn)
        :border 2))
    
    :variables '(("--accent-color" . :purple)
                 ("--spacing" . 12))))

;; Apply styles to objects
(let ((button (make-my-button :id :save-btn 
                              :classes '("primary")
                              :text "Save")))
  (apply-stylesheet *my-theme* (list button))
  ;; button now has computed styles applied
  (get-computed-style button))
  ; => (:background :red :color :white :padding 8 :font-weight :bold :border 2)
```

## Core Concepts

### Cascade contract and conformance matrix

The cascade is intentionally smaller than browser CSS and deterministic for TUI object trees.
Every declaration source is variable-resolved, shorthand-expanded, normalized, and validated
_before_ it participates in precedence. The winning order is:

1. explicitly declared property defaults,
2. inherited values for `:color`, `:font-size`, `:font-family`, and `:font-weight`,
3. matching stylesheet rules from low to high specificity, with later stylesheet source order winning exact ties,
4. inline style.

There is no `!important`, user/author origin split, media query cascade, or browser namespace cascade.
Within one declaration plist, normal Common Lisp plist last-value semantics apply after normalization.

| Concern | Contract | Conformance evidence |
| --- | --- | --- |
| Specificity | Lexicographic `(id class-like type)`; attributes/states/structural pseudo-classes count as class-like; combinators compose child specificity | selector specificity and edge-case tests |
| Source order | Equal-specificity rules retain stylesheet order; the later rule wins the same property | `cascade-source-order-breaks-specificity-ties` |
| Inline style | Applied after every stylesheet rule | inline cascade and explain-trace tests |
| Inheritance | Only the four documented inheritable properties flow from the parent, and only before child rules/inline values | inheritance and explain-trace tests |
| Variables | Recursive resolution before shorthand expansion; missing/cyclic references signal typed conditions unless `var` supplies a fallback | variable diagnostic/fallback tests |
| Invalid properties | Known static declarations are checked when rules are constructed and again after dynamic resolution/normalization | property contract tests |
| Invalid selectors | Selector shape is recursively validated by rule construction | `invalid-selector-fails-at-rule-construction` |
| Combinators | `:and`, `:or`, `:not`, child, descendant, and `:has` use the generic stylable-object protocol | selector/edge-case combinator tests |

`add-rule` appends to stylesheet source order and increments `stylesheet-revision`; removing a rule or changing variables also increments that revision.
Tree application currently performs a full recomputation. Legacy `cache`/`previous-signature` keyword arguments remain accepted for source compatibility but are deliberately ignored until cache dependencies are revision-safe.

### Stylable Objects

Objects must implement the `cl-styles.protocols` interface:

```lisp
(defclass my-widget ()
  ((id :initarg :id :accessor widget-id)
   (classes :initarg :classes :accessor widget-classes :initform nil)
   (element-type :initarg :type :accessor widget-type)
   (inline-style :initarg :style :accessor widget-inline-style :initform nil)
   (computed-style :accessor widget-computed-style :initform nil)
   (parent :accessor widget-parent :initform nil)
   (children :accessor widget-children :initform nil)))

;; Implement the protocol
(defmethod stylable-id ((obj my-widget)) (widget-id obj))
(defmethod stylable-classes ((obj my-widget)) (widget-classes obj))
(defmethod stylable-type ((obj my-widget)) (widget-type obj))
(defmethod stylable-inline-style ((obj my-widget)) (widget-inline-style obj))
(defmethod stylable-parent ((obj my-widget)) (widget-parent obj))
(defmethod stylable-children ((obj my-widget)) (widget-children obj))
(defmethod set-computed-style ((obj my-widget) style) 
  (setf (widget-computed-style obj) style) obj)
(defmethod get-computed-style ((obj my-widget)) (widget-computed-style obj))
```

### Selectors

cl-styles supports various CSS-style selectors:

```lisp
;; Type selectors
(type> :button)     ; Matches objects with type :button
(type> :div)        ; Matches objects with type :div

;; ID selectors  
(id> :my-id)        ; Matches object with id :my-id
(id> "save-btn")    ; Matches object with id "save-btn"

;; Class selectors
(cls> "primary")    ; Matches objects with class "primary"
(cls> :error)       ; Matches objects with class :error

;; Attribute selectors
(attr> :disabled t) ; Matches objects with disabled=t attribute

;; State selectors
(state> :focus)     ; Matches objects in :focus state

;; Combinators
(descendant> (type> :container) (cls> "item"))  ; .item inside container
(child> (id> :menu) (type> :button))            ; button direct child of #menu
(has (cls> "error"))                            ; Has child with .error class

;; Logical combinators
(sel-and (type> :button) (cls> "primary"))      ; button AND .primary
(sel-or (cls> "warning") (cls> "error"))        ; .warning OR .error  
(sel-not (cls> "disabled"))                     ; NOT .disabled
```

### Rules and Stylesheets

Define styling rules using `defrule` and combine them into stylesheets:

```lisp
;; Individual rule
(defrule (type> :button)
  :background :blue
  :color :white
  :border-radius 4
  :padding 8)

;; Stylesheet with multiple rules
(make-stylesheet
  :rules (list
    (defrule (type> :button)
      :background :gray
      :padding 6)
    
    (defrule (cls> "primary") 
      :background :blue)
    
    (defrule (id> :special-btn)
      :background :red
      :border 2))
  
  :variables '(("--main-bg" . :white)
               ("--text-color" . :black))
  
  :namespace :my-theme)
```

### CSS Variables

Define reusable values with CSS-style variables:

```lisp
;; Define variables in stylesheet
(make-stylesheet
  :variables '(("--primary-color" . :blue)
               ("--spacing-unit" . 8)
               ("--font-family" . "Arial"))
  
  :rules (list
    (defrule (type> :button)
      :background (var "--primary-color")
      :font-family (var "--font-family")
      :padding (var "--spacing-unit"))))

;; Variables are resolved when styles are applied
(apply-stylesheet sheet objects)
```

### Property Inheritance

Certain properties automatically inherit from parent to child:

```lisp
(defparameter *inheritable-props* '(:color :font-size :font-family :font-weight))

;; Parent styles are inherited by children
(let* ((parent (make-widget :type :container :style '(:color :blue :font-size 14)))
       (child (make-widget :type :text :style '(:font-weight :bold))))
  
  (setf (stylable-parent child) parent)
  (setf (stylable-children parent) (list child))
  
  (apply-stylesheet-to-tree parent sheet)
  
  ;; Child inherits :color and :font-size from parent
  (get-computed-style child))
  ; => (:font-weight :bold :color :blue :font-size 14)
```

## API Reference

### Core Functions

#### `make-stylesheet (&key rules variables namespace)`
Creates a new stylesheet.
- `rules`: List of style rules created with `defrule`
- `variables`: Alist of CSS variable definitions  
- `namespace`: Optional namespace identifier

#### `apply-stylesheet (sheet objects &key (return :patches))`
Apply stylesheet to a flat list of objects.
- `sheet`: Stylesheet to apply
- `objects`: List of objects implementing styling protocol
- `return`: `:patches` or `:objects`

#### `apply-stylesheet-to-tree (root sheet &key (return :patches))`
Apply stylesheet to object tree with inheritance.
- `root`: Root object of tree
- `sheet`: Stylesheet to apply  
- `return`: `:patches` or `:objects`

#### `explain-style (object sheet &key inherit-from)`
Compute without mutating `object` and return a `computed-style-result`. Its trace records each
winning or overridden declaration with origin (`:default`, `:inherited`, `:rule`, `:inline`),
selector, specificity, stylesheet source order, original declarations, and variable expansions.
The result revision records both the cascade-semantics revision and current stylesheet revision.

#### `compute-style-result (object matched-rules &key inherit-from sheet trace)`
Return the first-class computed style plus revision. Set `trace` true to collect declaration trace
data; ordinary `compute-style` and stylesheet application keep the trace-free fast path.

### Rule Creation

#### `defrule (selector &rest declarations)`
Create a style rule.
- `selector`: Selector expression (see selectors above)
- `declarations`: Property-value pairs (e.g., `:color :red :padding 8`)

### Tokens and Values

#### Color Values
```lisp
(rgb 255 0 0)           ; Red color
(rgba 255 0 0 128)      ; Red with alpha
(hsl 240 100 50)        ; Blue in HSL
:red :blue :green       ; Named colors
```

#### Length Values  
```lisp
(px 10)                 ; 10 pixels
(em 1.2)                ; 1.2 em units
(percent 50)            ; 50%
12                      ; Raw number
```

#### Variables
```lisp
(var "--my-variable")   ; Reference CSS variable
(var :my-keyword-var)   ; Keyword variable reference
(var "--optional" :fallback) ; Use fallback if missing or recursively invalid
```

### Property Groups

Properties are organized into logical groups for layout systems:

```lisp
;; Box model
:padding :margin :border              ; Box properties
:padding-top :padding-left            ; Specific sides

;; Flexbox
:display :flex-direction :flex-wrap   ; Flex container
:justify-content :align-items         ; Flex alignment
:flex-grow :flex-shrink :flex-basis   ; Flex items

;; Grid  
:grid-template-columns :grid-template-rows  ; Grid template
:grid-gap :gap :row-gap :column-gap         ; Grid spacing
:justify-items :align-items                 ; Grid alignment

;; Typography
:color :font-family :font-size :font-weight ; Text styling
```

## Advanced Usage

### Custom Property Types

Define custom property validation:

```lisp
(defproperty :my-custom-prop 
  :type (lambda (v) (and (numberp v) (> v 0)))
  :default 1
  :doc "Custom positive number property")
```

### Property Groups for Layouts

Group properties by layout type:

```lisp
;; Get all properties for flex layout
(properties-for-layout :flex)
; => (:display :flex-direction :justify-content :align-items 
;     :padding :margin :border ...)

;; Define custom layout group
(groups-for-layout :my-layout :box :custom-group)
```

### Stylesheet Manipulation

```lisp
;; Add rules dynamically  
(add-rule sheet (defrule (cls> "new-class") :color :green))

;; Remove rules
(remove-rule sheet existing-rule)

;; Chain operations
(-> sheet
    (add-rule (defrule (type> :new-type) :background :yellow))
    (remove-rule old-rule))
```

### Error Handling

cl-styles provides specific error types for validation:

```lisp
(handler-case
  (apply-stylesheet invalid-sheet objects)
  (style-contract-violation (e)
    (format t "Property ~A expected ~A but got ~A" 
            (where e) (expected e) (got e)))
  (missing-style-variable (e)
    (format t "Missing variable ~A through ~S"
            (style-variable-name e) (style-variable-chain e)))
  (style-variable-cycle (e)
    (format t "Variable cycle ~S" (style-variable-chain e))))
```

### Performance Tips

```lisp
;; Batch operations when possible
(apply-stylesheet sheet all-objects)

;; Use tree application for inheritance
(apply-stylesheet-to-tree root sheet)

;; Stylesheet mutations increment stylesheet-revision.
;; Tree application currently recomputes fully; unsafe legacy cache arguments are ignored.

;; Profile with large object counts
(time (apply-stylesheet sheet large-object-list))
```

## Examples

### TUI Button Styling

```lisp
(defvar *button-theme*
  (make-stylesheet
    :rules (list
      ;; Base button style
      (defrule (type> :button)
        :background :gray
        :color :white  
        :border 1
        :padding 4)
      
      ;; Button states
      (defrule (sel-and (type> :button) (state> :hover))
        :background :light-gray)
      
      (defrule (sel-and (type> :button) (state> :active))  
        :background :dark-gray)
      
      (defrule (sel-and (type> :button) (attr> :disabled t))
        :background :very-light-gray
        :color :gray)
      
      ;; Button variants
      (defrule (cls> "primary")
        :background :blue)
      
      (defrule (cls> "danger") 
        :background :red)
      
      (defrule (cls> "large")
        :padding 8
        :font-size 16))
    
    :variables '(("--button-radius" . 3)
                 ("--primary-color" . :blue))))

;; Usage
(defun style-button (button)
  (apply-stylesheet *button-theme* (list button))
  button)
```

### Layout with Inheritance

```lisp
(defvar *layout-theme*
  (make-stylesheet
    :rules (list
      ;; Container styles  
      (defrule (type> :container)
        :font-family "Arial"
        :font-size 12
        :color :black)
      
      ;; Headers inherit and override
      (defrule (type> :header)
        :font-size 16
        :font-weight :bold
        :margin-bottom 8)
      
      ;; Paragraphs inherit base styles
      (defrule (type> :paragraph)
        :margin-bottom 4
        :line-height 1.4))))

(defun create-document ()
  (let* ((doc (make-widget :type :container))
         (header (make-widget :type :header :text "Title"))
         (para1 (make-widget :type :paragraph :text "First paragraph"))
         (para2 (make-widget :type :paragraph :text "Second paragraph")))
    
    ;; Set up hierarchy
    (setf (stylable-children doc) (list header para1 para2))
    (dolist (child (list header para1 para2))
      (setf (stylable-parent child) doc))
    
    ;; Apply styles with inheritance
    (apply-stylesheet-to-tree doc *layout-theme*)
    doc))
```

### Dynamic Theming

```lisp
(defun create-theme (primary-color accent-color)
  "Create a theme with dynamic colors"
  (make-stylesheet
    :variables `(("--primary" . ,primary-color)
                 ("--accent" . ,accent-color)
                 ("--spacing" . 8))
    
    :rules (list
      (defrule (type> :button)
        :background (var "--primary")
        :padding (var "--spacing"))
      
      (defrule (cls> "accent")
        :color (var "--accent"))
      
      (defrule (cls> "highlight")
        :background (var "--accent")
        :color :white))))

;; Create different themes
(defvar *blue-theme* (create-theme :blue :light-blue))
(defvar *dark-theme* (create-theme :dark-gray :orange))

;; Switch themes dynamically
(defun apply-theme (theme objects)
  (apply-stylesheet theme objects))
```

## Testing

Run the test suite:

```bash
clpm bundle exec --with-client sbcl -- \
  --noinform --non-interactive \
  --eval '(require :asdf)' \
  --eval '(asdf:test-system "cl-styles")'
```

The test suite includes:
- Unit tests for all core components
- Integration tests for complex scenarios  
- Property validation tests
- Error handling tests
- Performance smoke tests

## Architecture

cl-styles uses a direct processing model:

1. **Stylesheets** contain rules and variables
2. **Rules** combine selectors with property declarations  
3. **Selectors** match objects based on their properties
4. **Engine** applies rules in specificity order with inheritance
5. **Properties** are validated and normalized

The library avoids compilation overhead in favor of simplicity and debuggability, making it ideal for TUI applications where styling happens infrequently compared to rendering.

## Contributing

cl-styles follows standard Common Lisp development practices:

- Use kebab-case for files and functions
- Comprehensive test coverage required
- Documentation for public API
- Follow established code style

## License

MIT License - see LICENSE file for details.