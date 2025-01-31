# cl-styles

`cl-styles` is a Common Lisp library for styling arbitrary objects. It provides a flexible and extensible system for applying styles to objects based on a set of generics.

## Features

- Define styles using a simple and expressive syntax.
- Apply styles to objects based on class, ID, or other selectors.
- Support for cascading styles and specificity.
- Extensible API for custom styling logic.

## Installation

To install `cl-styles`, clone the repository and load it into your Lisp environment.

```sh
git clone https://github.com/yourusername/cl-styles.git
cd cl-styles
make
```

## Usage

```lisp
;; Define a stylesheet
(defvar my-stylesheet
  (defstylesheet
    (defrule (cls> "button")
      (:bg-color :blue :fg-color :white :box :single))))

;; Apply the stylesheet to an object
(apply-stylesheet my-stylesheet my-object)
```

## Contributing

Contributions are welcome! Please submit a pull request or open an issue on GitHub.

## License

This project is licensed under the MIT License.
