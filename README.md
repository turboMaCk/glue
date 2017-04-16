# TEA Component

This package helps you to reduce boilerplate while composing TEA-based (The Elm Architecture) applications using
[`Cmd.map`](http://package.elm-lang.org/packages/elm-lang/core/5.1.1/Platform-Cmd#map),
[`Sub.map`](http://package.elm-lang.org/packages/elm-lang/core/5.1.1/Platform-Sub#map)
and [`Html.map`](http://package.elm-lang.org/packages/elm-lang/html/2.0.0/Html#map).
`Component` also respects TEA's design decisions and philosophy and introduces as little abstraction over basic TEA constructs as possible.
It's fair to say that `Component` is an alternative to [elm-parts](http://package.elm-lang.org/packages/debois/elm-parts/latest),
but uses a different approach (no better or worse) for composing smaller pieces into larger ones.

**This package is highly experimental and might change a lot over time.**

Feedback and contributions to both code and documentation are very welcome.

## tl;dr

This package is a result of my experience with building larger application in elm by composing
smaller pieces together. The goals and features of this package are:

- Reduce boilerplate in `update` and `init` functions.
- Simple and easy to use management of components (Something like what [`Html.program`](http://package.elm-lang.org/packages/elm-lang/html/2.0.0/Html#program)
or legacy [`start-app`](http://package.elm-lang.org/packages/evancz/start-app/latest) did to TEA).
- Don't enforce changes in sub-components to make them compatible (since they're more likely to be isolated from the rest of the app).
- Keep all glueing logic in one tiny layer (the `Component` type in this case).
- Make it possible to turn a standalone Elm app into a component.
- Make it possible to use with [`Polymorphic Components`](#wrap-polymorphic-component).
- Support [`Action Bubbling`](#action-bubbling) from child components to the parent component.

## Install

Is as you would expect...

```
$ elm-package install turboMaCk/tea-component
```

## Examples

Best place to start is probably to have a look at [examples](https://github.com/turboMaCk/component/tree/master/examples).

In particular, you can find:

### [Transforming Isolated Elm App to Component](https://github.com/turboMaCk/component/tree/master/examples/counter)

### [Composing Components with Subscriptions](https://github.com/turboMaCk/component/tree/master/examples/subscriptions)

### [Action Bubbling (Sending Actions from Child to Parent)](https://github.com/turboMaCk/component/tree/master/examples/bubbling)

## Why?

TEA is an awesome way to write Html-based apps in Elm. However, not every application can be defined just in terms of `Model`, `update`, and `view`.
Basic separation of [`Html.program`](http://package.elm-lang.org/packages/elm-lang/html/2.0.0/Html#program) is really nice for small apps
but tends to grow pretty quickly in an unmanageable way. In addition, not everyone believes that keeping so much stuff in a few giant blobs is a good way
to organize every application. The [official website](http://elm-lang.org/) claims, "No full rewrites, no huge time investment," yet it offers
only [`interop`](https://guide.elm-lang.org/interop/) as an answer, which is nowhere near to being a full solution for moving from embedded elm components
to Elm-only SPA (single-page app).

It's clear that there is a real need to make TEA apps composable.
This is when [`Cmd.map`](http://package.elm-lang.org/packages/elm-lang/html/2.0.0/Html#map),
[`Sub.map`](http://package.elm-lang.org/packages/elm-lang/core/5.1.1/Platform-Sub#map)
and [`Html.map`](http://package.elm-lang.org/packages/debois/elm-parts/latest) can become handy.
They allow you to start nesting `init`, `update`, `subscriptions` and `view` into larger pieces.
Here is how the `Model` and `Msg` types of a parent application might look:

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

Basically, the top-level component only holds the `Model` of a sub-component as a single value, and wraps its `Msg` inside one of its `Msg` constructors.
Of course, `init`, `update`, and `subscriptions` also have to know how to work with sub-components, and there you need
[`Cmd.map`](http://package.elm-lang.org/packages/elm-lang/html/2.0.0/Html#map),
[`Html.map`](http://package.elm-lang.org/packages/debois/elm-parts/latest) and
[`Sub.map`](http://package.elm-lang.org/packages/elm-lang/core/5.1.1/Platform-Sub#map).
For instance, this is how delegation of `Msg` in `update` might look:

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

As you can see, this is quite neat even though it requires some boiler-plate code.
Let's take a look at `view` and [`Html.map`](http://package.elm-lang.org/packages/debois/elm-parts/latest) in action:

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
[`Html.map`](http://package.elm-lang.org/packages/debois/elm-parts/latest) in `subscriptions` to finish integrating a sub-component into a higher-level one.

**And this is as far as pure TEA goes. This may possibly be enough for you, and that's OK. Why might you still want to use this `Component` package?**

- Without `Component`, the approach requires a lot of boilerplate code inside `update`, `init`, and `subscriptions`.
- In each place, you're handling both the parent and the child component at the same time.
- Often, changes in a sub-component require changes in its parent as well.
- Glueing lacks a common interface and tends to change a lot over time.

## How?

The most important type that TEA is built around is `( Model, Cmd Msg )`. All we're missing is just a tiny abstraction that will
make working with this pair easier. This is really the core idea of the whole `Component` package.

To simplify glueing things together, the `Component` type is introduced by this package.
In the same way that `Html.Program` glues TEA together with `init`, `update`, `view`, and `subscriptions`, `Component.Component` glues parent and child APIs.
Unlike `Program`, `Component` is in fact just bunch of functions that do nothing by themselves.
Other functions within the `Component` package then use the `Component.Component` type as proxy to its glue logic.

### Using TEA App as Component

This is how we can construct the `Component` type for [counter example](https://guide.elm-lang.org/architecture/user_input/buttons.html):

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
All mapping from one type to another happens in here. This is different in the case of [polymorphic components](#wrap-polymorphic-component),
but more about this later. With `Component` defined, we can go and integrate it with the parent.

Before we do so, however, this is what the parent's `Model` and `Msg` looks like.
Based on the `Component` type definition, we know we're expecting `Model` and `Msg` to be as follows:

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

### Wrap Polymorphic Component

A "polymorphic component" is what I call TEA components that have to be integrated into some other app.
This basically means they are using `Cmd.map`, `Html.map`, and `Sub.map` internally. Let's make `Counter.elm` polymorphic.
This will require us to add one extra argument to its `view` function and a small change to the type annotations of `init` and `update`:

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

Then we need to change our `Component` definition in the higher-level component to reflect the new API of children components:

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

This is all that is required when a child component's API changes.
Since the `Component` type holds all glue code in one place, there is no need for changes in the parent's `init`, `update`, or `view` functions.

### Action Bubbling

If your component is [polymorphic](#wrap-polymorphic-component) you can easily send `Cmd` to its parent.
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

As an example, we can use the (polymorphic) `Counter.elm` again. Let's say we want to send some action to the parent when the counter's value is even.
For this we need to define a helper function in `Counter.elm`:

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

`isEven` is pretty straightforward. It just returns `True` or `False` for a given `Int`.
`notifyEven` takes the parent's `Msg` constructor and either [`perform`](http://package.elm-lang.org/packages/GlobalWebIndex/cmd-extra/1.0.0/Cmd-Extra#perform)s
it as `Cmd`, or returns `Cmd.none` in the case of an odd number.

Now we need to change `init` and `update` so they're emitting this new `Cmd`.
The simplest way is just to make them both accept a `msg` constructor as following:

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

Now both `init` and `update` should send `Cmd` when `Model` is an even number.
This is a breaking change to `Counter`'s API so we will need to change its parent integration as well.
Since we want to actually use this message and do something with it let me first update the parent's `Msg` and `Model`:

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

This completes the changes to `Model`. Now we need to update our `update` function so it can handle the `Even` message.

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
This is to show you why you might need to update both the parent's and child's `Model` on a single `Msg` (`CounterMsg` in this case), and how to do it.

Now we need to handle the `Even` action itself. This simply sets `even = True` in the model.

Since the parent is ready to handle actions from `Counter` our last step is simply to update the `Component` type definition and glue the new APIs together:

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

There we simply pass the parent's `Even` constructor to the `update` and `init` functions of the child.
This is all we need to do to wire `Cmd` from child to parent.

See this [complete example](https://github.com/turboMaCk/component/tree/master/examples/bubbling) to learn more.

## Re-evaluating and Future Work

This package is still in a really early stage of development and needs to be tested in the field.
Personally I still need to sort out a few things.
For instance is it really a good idea to include `view` handling, since not every `Component` (or maybe rather `Service` in that case) actually has to have a view?
Anyway I hope this provides a good base for further improvements and discussion of how to compose larger apps with TEA.

## License

BSD-3-Clause

Copyright 2017 Marek Fajkus
