module Polyform.Validation where

import Prelude

import Control.Alt (class Alt, (<|>))
import Control.Apply (lift2)
import Data.Bifunctor (class Bifunctor)
import Data.Monoid (class Monoid, mempty)
import Data.Newtype (class Newtype, unwrap)

-- Nearly (Tuple e (Maybe a)) but without monad instance
data V e a = Invalid e | Valid e a
derive instance functorV ∷ Functor (V e)

instance bifunctorV ∷ Bifunctor V where
  bimap f _ (Invalid e) = Invalid (f e)
  bimap f g (Valid e a) = Valid (f e) (g a)

instance applyV ∷ (Semigroup e) ⇒ Apply (V e) where
  apply (Valid m1 f) (Valid m2 a) = Valid (m1 <> m2) (f a)
  apply (Invalid m1) (Valid m2 _) = Invalid (m1 <> m2)
  apply (Invalid m1) (Invalid m2) = Invalid (m1 <> m2)
  apply (Valid m1 _) (Invalid m2) = Invalid (m1 <> m2)

derive instance eqV ∷ (Eq e, Eq a) => Eq (V e a)
derive instance ordV ∷ (Ord e, Ord a) => Ord (V e a)

instance showV ∷ (Show e, Show a) => Show (V e a) where
  show (Invalid e) = "(Invalid " <> show e <> ")"
  show (Valid e a) = "(Valid " <> show e <> " " <> show a <> ")"

instance applicativeV ∷ (Monoid e) ⇒ Applicative (V e) where
  pure a = Valid mempty a

instance altV ∷ (Semigroup e) ⇒ Alt (V e) where
  alt (Invalid e1) (Invalid e2) = Invalid (e1 <> e2)
  alt (Valid e1 r) (Valid e2 _) = Valid (e1 <> e2) r
  alt (Invalid e1) (Valid e2 r) = Valid (e1 <> e2) r
  alt (Valid e1 r) (Invalid e2) = Valid (e1 <> e2) r

instance semigroupV :: (Semigroup err, Semigroup a) => Semigroup (V err a) where
  append = lift2 append

instance monoidV :: (Monoid e, Monoid a) => Monoid (V e a) where
  mempty = pure mempty

newtype Validation m e a b = Validation (a → m (V e b))
derive instance newtypeVaildation ∷ Newtype (Validation m e a b) _
derive instance functorValidation ∷ (Functor m) ⇒ Functor (Validation m e a)

instance applyValidation ∷ (Semigroup e, Monad m) ⇒ Apply (Validation m e a) where
  apply vf va = Validation $ \i → do
    vf' ← unwrap vf i
    va' ← unwrap va i
    pure $ vf' <*> va'

instance applicativeValidation ∷ (Monoid e, Monad m) ⇒ Applicative (Validation m e a) where
  pure = Validation <<< const <<< pure <<< pure

instance altValidation ∷ (Alt m) ⇒ Alt (Validation m e a) where
  alt (Validation v1) (Validation v2) = Validation (\a → v1 a <|> v2 a)

instance semigroupValidation ∷ (Semigroup (m (V e b))) ⇒ Semigroup (Validation m e a b) where
  append (Validation v1) (Validation v2) = Validation (\a → v1 a <> v2 a)

instance monoidValidation ∷ (Applicative m, Monoid e, Monoid b, Semigroup (m (V e b))) ⇒ Monoid (Validation m e a b) where
  mempty = Validation <<< const <<< pure $ mempty

instance semigroupoidValidation ∷ (Monad m, Semigroup e) ⇒ Semigroupoid (Validation m e) where
  compose v2 v1 =
    Validation $ (\a → do
      eb ← unwrap v1 a
      case eb of
        Valid e b → do
          r ← unwrap v2 b
          pure $ case r of
            Valid e' c → Valid (e <> e') c
            Invalid e' → Invalid (e <> e')
        Invalid e → pure (Invalid e))

instance categoryValidation ∷ (Monad m, Monoid e) ⇒ Category (Validation m e) where
  id = Validation $ pure <<< pure

ask ∷ ∀ a e m. Monad m ⇒ Monoid e ⇒ Validation m e a a
ask = Validation (\a → pure (Valid mempty a))

liftV ∷ ∀ a e b m. Monad m ⇒ Monoid e ⇒ (a → V e b) → Validation m e a b
liftV f = ask >>> (Validation $ f >>> pure)


-- | `ValidationT` lifts `Validation` into monad by loosing
-- | accumulative nature of Applicative.
-- | It is really isomorphic to (Star (ExceptT e m) a b) or.
newtype ValidationT m e a b = ValidationT (Validation m e a b)
derive instance newtypeVaildationT ∷ Newtype (ValidationT m e a b) _
derive instance functorValidationT ∷ (Functor m) ⇒ Functor (ValidationT m e a)
derive newtype instance semigroupoidValidationT ∷ (Monad m, Semigroup e) ⇒ Semigroupoid (ValidationT m e)
derive newtype instance categoryValidationT ∷ (Monad m, Monoid e) ⇒ Category (ValidationT m e)

instance applyValidationT ∷ (Monad m) ⇒ Apply (ValidationT m e a) where
  apply vf va = ValidationT $ Validation $ \i → do
    vf' ← unwrap (unwrap vf) i
    va' ← unwrap (unwrap va) i
    pure $ case vf' of
      Valid e f → f <$> va'
      Invalid e → Invalid e

instance applicativeValidationT ∷ (Monoid e, Monad m) ⇒ Applicative (ValidationT m e a) where
  pure = ValidationT <<< pure

instance bindValidationT ∷ (Monoid e, Monad m) ⇒ Bind (ValidationT m e a) where
  bind (ValidationT (Validation ma)) f = ValidationT $ Validation $ \i → do
    va ← ma i
    case va of
      Invalid e → pure $ Invalid e
      Valid e a → do
        let (ValidationT (Validation vb)) = f a
        vb i

instance monadValidationT ∷ (Monoid e, Monad m) ⇒ Monad (ValidationT m e a)
