# TEA Component

This package helps you to reduce boilerplate while composing TEA (The Elm Architecture) based application using
[`Cmd.map`](http://package.elm-lang.org/packages/elm-lang/core/5.1.1/Platform-Cmd#map),
[`Sub.map`](http://package.elm-lang.org/packages/elm-lang/core/5.1.1/Platform-Sub#map)
and [`Html.map`](http://package.elm-lang.org/packages/elm-lang/html/2.0.0/Html#map).
`Component` also respect TEA's design decisions and philosophy and introduces as little abstraction over basic TEA constructs as possible.
It's fair to say that `Component` is alternative to [elm-parts](http://package.elm-lang.org/packages/debois/elm-parts/latest)
but uses different (no better or worst) approach for composing smaller pieces to larger ones.

**This package is highly experimental and might change a lot over time.**

Feedback and contributions to both code and documentation are very welcome.

## tl;dr

This package is result of my experience with building larger application in elm by composing
smaller pieces together. Goals and features of this package are:

- Reduce boilerplate in `update` and `init` functions.
- Simple and easy to use management of components (Something like what [`Html.program`](http://package.elm-lang.org/packages/elm-lang/html/2.0.0/Html#program)
or legacy [`start-app`](http://package.elm-lang.org/packages/evancz/start-app/latest) did to TEA).
- Don't enforce changes in lower component to make them compatible (since they're more likely to be isolated from rest of app).
- Keep all gluing logic in one tiny layer (`Component` type in this case).
- Make it possible to turn standalone Elm app to component.
- Make it possible to use with [`Polymorphic Components`](#wrap-polymorfic-component).
- Support [`Action Bubbling`](#action-bubbling) from child component to parent one.

## Install

As you expected...

```
$ elm-package install turboMaCk/component
```

## Examples

Best place to start is probably to have a look at [examples](https://github.com/turboMaCk/component/tree/master/examples).

Namely you can find:

### [Transforming Isolated Elm App to Component](https://github.com/turboMaCk/component/tree/master/examples/counter)

### [Composing Components with Subscriptions](https://github.com/turboMaCk/component/tree/master/examples/subscriptions)

### [Action Bubbling (Sending Actions from Child to Parent)](https://github.com/turboMaCk/component/tree/master/examples/bubbling)

## Why?

TEA is awesome way to write Html based apps in Elm. However not every application can be defined just in terms of `Model` `update` and `view`.
Basics separation of [`Html.program`](http://package.elm-lang.org/packages/elm-lang/html/2.0.0/Html#program) is really nice for small apps
but tends to grow pretty quickly in unmanageable way. Also not everyone believes that keeping so much stuff in few giant blobs is good way
to organize every application. [Official website](http://elm-lang.org/) claims "No full rewrites, no huge time investment." yet it only offers
only [`interop`](https://guide.elm-lang.org/interop/) as answer which is no near to be full solution for moving from embedded elm components
to elm only SPA.

It's clear that there real need to make TEA apps composable.
This is when [`Cmd.map`](http://package.elm-lang.org/packages/elm-lang/html/2.0.0/Html#map),
[`Sub.map`](http://package.elm-lang.org/packages/elm-lang/core/5.1.1/Platform-Sub#map)
and [`Html.map`](http://package.elm-lang.org/packages/debois/elm-parts/latest) can become handy.
They allows you to start nesting `init`, `update`, `subscribtions` and `view` to larger pieces.
This is how `Model` and `Msg` of parent application might looks like:

```elm
import SubComponent

type alias Model =
    { ...
    , subComponentModel : SubComponent.Model
    , ...
    }

type Msg
    = ...
    | SubComponentMsg SubComponent.Msg
    | ...
```

Basically top components only holds `Model` of sub-component as single value and wraps it's `Msg` inside one of its `Msg` constructors.
Of course also `init` `update` and `subscribes` has to know how to works with sub-components and there you need
[`Cmd.map`](http://package.elm-lang.org/packages/elm-lang/html/2.0.0/Html#map),
[`Html.map`](http://package.elm-lang.org/packages/debois/elm-parts/latest) and
[`Sub.map`](http://package.elm-lang.org/packages/elm-lang/core/5.1.1/Platform-Sub#map).
For instance this is how delegation of `Msg` in `update` might look like:

```elm
update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        ...
        SubComponentMsg subMsg ->
            let
                ( subModel, subCmd ) =
                    SubComponent.update subMsg model.subComponentModel
            in
                ( { model | subComponentModel = subModel }, Cmd.map SubComponentMsg subCmd )
        ...
```

As you can see this is quite neat even though it requires some boiler-plate code.
Let's have a look how view and [`Html.map`](http://package.elm-lang.org/packages/debois/elm-parts/latest) in action:

```elm
view : Model -> Html Msg
view model =
   Html.div
       []
       [ ...
       , Html.map SubComponentMsg <| SubComponent.view model.subComponentModel
       , ... ]
```

You can use [`Cmd.map`](http://package.elm-lang.org/packages/elm-lang/html/2.0.0/Html#map) inside `init` as well and
[`Sub.map`](http://package.elm-lang.org/packages/elm-lang/core/5.1.1/Platform-Sub#map) which is fairly similar to
[`Html.map`](http://package.elm-lang.org/packages/debois/elm-parts/latest) in `subscriptions` to finish integration of sub-component to upper one.

**And this is as far as pure TEA can goes. This can be possibly enough for you and that's OK. Why you might still want to use `Component` package?**

- This approach requires a lot of boilerplate code inside `update` `init` and `subscriptions`.
- On all places you're handling both parent and child component at the same time.
- Often changes in sub-component requires changes in its parent as well.
- Gluing lacks any common interface and tends to change a lot over time.

## How?

The most important type TEA is build around is `( Model, Cmd Msg )`. All we miss is just tiny abstraction that will
make working with this pair easier. This is really the core idea of whole `Component` package.

To simplify gluing as well `Component` type is introduced by this package.
Same way `Html.Program` glues TEA together `init`, `update`, `view` and `subscriptions` `Component.Component` glues parent and child APIs.
Unlike `Program` `Component` is in fact just bunch of functions which doesn't do anything by itself.
Other functions within `Component` package then using `Component.Component` type as proxy to its glue logic.

### Using TEA App as Component

This is how we can construct `Component` type for [counter example](https://guide.elm-lang.org/architecture/user_input/buttons.html):

```elm
import Counter

counter : Component Model Counter.Model Msg Counter.Msg
counter =
    Component.component
        { model = \subModel model -> { model | counterModel = subModel }
        , init = Counter.init |> Component.map CounterMsg
        , update =
            \subMsg model ->
                Counter.update subMsg model.counterModel
                    |> Component.map CounterMsg
        , view = \model -> Html.map CounterMsg <| Counter.view model.counterModel
        , subscriptions = \_ -> Sub.none
        }
```
All mapping from one type to another happens in here. This is different in case of [polymorfic components](#wrap-polymorfic-component)
but more about this later. With `Component` define we can go and integrate it to parent.

Before we do so this is how parent's `Model` and `Msg` looks like.
Based on `Component` type definition we know we're expecting `Model` and `Msg` to be like:

```elm
type alias Model =
    { counterModel : Counter.Model }

type Msg
    = CounterMsg Counter.Msg
```

And this is our `init`, `update` and `view`:

```elm

init : ( Model, Cmd msg )
init =
    ( Model, Cmd.none )
        |> Component.init counter

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        CounterMsg counterMsg ->
            ( model, Cmd.none )
                |> Component.update counter counterMsg

view : Model -> Html Msg
view =
    Component.view counter
```

### Wrap Polymorfic Component

Polymorphic component is what I call TEA components that has to be integrated to some other app.
This basically means they are using `Cmd.map`, `Html.map` and `Sub.map` internally. Let's make `Counter.elm` polymorphic.
This will require us to add one extra argument to its `view` function and small change in type annotations for `init` and `update`:

```elm
init : ( Model, Cmd msg )

update : Msg -> Model -> ( Model, Cmd msg )

view : (Msg -> msg) -> Model -> Html msg
view msg model =
    Html.map msg <|
        Html.div
            []
            [ Html.button [ Html.Events.onClick Decrement ] [ Html.text "-" ]
            , Html.text <| toString model
            , Html.button [ Html.Events.onClick Increment ] [ Html.text "+" ]
            ]
```

Then we need to change our `Component` definition in upper component to reflect new API of children:

```elm
counter : Component Model Counter.Model Msg Counter.Msg
counter =
    Component.component
        { model = \subModel model -> { model | counter = subModel }
        , init = Counter.init
        , update = \subMsg model -> Counter.update subMsg model.counter
        , view = \model -> Counter.view CounterMsg model.counter
        , subscriptions = \_ -> Sub.none
        }
```

This is all what is required when child component API changes.
Since `Component` type holds all gluing there is no need for changes in parent's `init`, `update` and `view`.

### Action Bubbling

If your component is [polymorfic](#wrap-polymorfic-component) you can easily send `Cmd` to it's parent.
Please check [cmd-extra](http://package.elm-lang.org/packages/GlobalWebIndex/cmd-extra/latest) package
which helps you construct `Cmd Msg` from `Msg`.

Using `Cmd` for communication with upper component works like this:

```text
    +------------------------------------+
    |                                    |
    v                                    |
+-----------------------------------+    |
|                                   |    |
| Parent Component                  |    |
|                                   |    +
|   +                               |  Cmd Msg
|   |                               |    |
|  Model                            |    |
|   |                               |    |
|   |   +------------------------+  |    |
|   |   |                        |  |    |
|   |   | Child Component        |  |    |
|   |   |                        |  |    |
|   +-> |                        +-------+
|       +------------------------+  |
|                                   |
+-----------------------------------+

```

As an example we can use (polymorphic) `Counter.elm` again. Let's say we want to send some action to parent when counter's model is even.
For this we need to define helper function in `Counter.elm`.

```elm
isEven : Int -> Bool
isEven =
    (==) 0 << (Basics.flip (%)) 2


notifyEven : msg -> Model -> Cmd msg
notifyEven msg model =
    if isEven model then
        Cmd.Extra.perform msg
    else
        Cmd.none
```

`isEven` is pretty strait forward. It's just returns `True/False` for given `Int`.
`notifyEven` takes parent's `Msg` constructor and either [`perform`](http://package.elm-lang.org/packages/GlobalWebIndex/cmd-extra/1.0.0/Cmd-Extra#perform)
it as `Cmd` or return `Cmd.none` in case of odd number.

Now we need to change `init` and `update` so it's emitting this new `Cmd`.
The simplest way is just to make them both accept `msg` constructor as following:

```elm
init : msg -> ( Model, Cmd msg )
init msg =
    let
        model = 0
    in
        ( model, notifyEven msg model )


update : msg -> Msg -> Model -> ( Model, Cmd msg )
update notify msg model =
    let
        newModel =
            case msg of
                Increment ->
                    model + 1

                Decrement ->
                    model - 1
    in
        ( newModel, notifyEven notify newModel )
```

Now both `init` and `update` should send `Cmd` when `Model` is even number.
This is breaking change in `Counter`'s API so we will need to change its parent integration as well.
Anyway since we want to actually use this message and do something with it let me first update parent's `Msg` and `Model`:

```elm
type alias Model =
    { even : Bool
    , counter : Counter.Model
    }

type Msg
    = CounterMsg Counter.Msg
    | Even
```

Because we've changed `Model` (added `even : Bool`) we should change `init` and `view` as well:

```elm
init : ( Model, Cmd Msg )
init =
    ( Model False, Cmd.none )
        |> Component.init counter

view : Model -> Html Msg
view model =
    Html.div []
        [ Component.view counter model
        , if model.even then
            Html.text "is even"
          else
            Html.text "is odd"
        ]
```

This solves changes in model. Now we need to update our `update` so it can handle `Even` `Msg`.

```elm
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        CounterMsg counterMsg ->
            ( { model | even = False }, Cmd.none )
                |> Component.update counter counterMsg

        Even ->
            ( { model | even = True }, Cmd.none )
```

As you can see we're setting `even` to `False` on every `CounterMsg`.
This is because `Counter` is just emitting `Cmd` when its `Model` is Even.
This is to show you why you might need to update both parent's and child's `Model` on single `Msg` (`CounterMsg` in this case) and how to do it.

Now we need to handle `Even` action itself. This simply sets `even = True` in model.

Since parent is ready to handle actions from `Counter` our last step is simply to update `Component` type definition and glue new APIs together:

```elm
counter : Component Model Counter.Model Msg Counter.Msg
counter =
    Component.component
        { model = \subModel model -> { model | counter = subModel }
        , init = Counter.init Even
        , update = \subMsg model -> Counter.update Even subMsg model.counter
        , view = \model -> Counter.view CounterMsg model.counter
        , subscriptions = \_ -> Sub.none
        }
```

There we simply pass parent's `Even` `Msg` constructor to `update` and `init` of child.
This is all we need to do to wire `Cmd` from child to parent.

See [complete example](https://github.com/turboMaCk/component/tree/master/examples/bubbling) to learn more.

## Reevaluating and Future

This package is still in really early stage and needs to be tested in field.
Personally I still need to sort out few things.
For instance is it really good idea to include `view` handling since not every `Component` (or maybe rather `Service` in that case) actually has to have view?
Anyway I hope this provides good base for further improvements and discussion of how to compose larger apps with TEA.

## License

BSD-3-Clause

Copyright 2017 Marek Fajkus
