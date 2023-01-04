{ sources = [ "src/**/*.purs", "test/**/*.purs" ]
, license = "BSD-3-Clause"
, name = "polyform"
, dependencies =
  [ "arrays"
  , "bifunctors"
  , "control"
  , "effect"
  , "either"
  , "enums"
  , "functors"
  , "heterogeneous"
  , "identity"
  , "invariant"
  , "lists"
  , "maybe"
  , "newtype"
  , "ordered-collections"
  , "parallel"
  , "partial"
  , "prelude"
  , "profunctor"
  , "quickcheck"
  , "quickcheck-laws"
  , "record"
  , "transformers"
  , "tuples"
  , "type-equality"
  , "typelevel-prelude"
  , "unsafe-coerce"
  , "js-unsafe-stringify"
  , "validation"
  , "variant"
  ]
, packages = ./packages.dhall
, repository = "https://github.com/purescript-polyform/polyform.git"
}
