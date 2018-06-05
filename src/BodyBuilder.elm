module BodyBuilder
    exposing
        ( BlockAttributes
        , FlexItem
        , GridItem
        , Node
        , NodeWithStyle
        , Option
        , a
        , article
        , aside
        , audio
        , br
        , button
        , div
        , embed
        , flex
        , flexItem
        , footer
        , grid
        , gridItem
        , h1
        , h2
        , h3
        , h4
        , h5
        , h6
        , header
        , img
        , inputCheckbox
        , inputColor
        , inputFile
        , inputHidden
        , inputNumber
        , inputPassword
        , inputRadio
        , inputRange
        , inputSubmit
        , inputTel
        , inputText
        , inputUrl
        , nav
        , node
        , none
        , option
        , p
        , progress
        , section
        , select
        , span
        , staticPage
        , text
        , textarea
        )

{-| This module entirely replaces Html, providing a type-safer alternatives.
This also manages inlining styling through Elegant.
It is perfectly compatible with Html, though.

  - [Types](#types)
      - [Elements](#elements-types)
      - [Attributes](#attributes)
  - [Elements](#elements)
      - [Special](#special)
      - [Inline](#inline)
      - [Block](#block)
  - [Program](#program)


# Types


## Elements Types

@docs Node, FlexItem, GridItem, Option


## Attributes

@docs BlockAttributes


# Elements


## Special

@docs text, none, flexItem, gridItem, option, br


## Inline

Those elements are inline by default. However, their behavior can be overrided by
using `Style.block []`. They become block, and behaves like this.

@docs node, span, flex, grid, a, button, img, audio, inputColor, inputFile, inputHidden, inputNumber, inputCheckbox, inputPassword, inputRadio, inputRange, inputSubmit, inputTel, inputText, inputUrl, progress, select, textarea


## Block

Those elements are block by default. Their behavior can't be overrided.
It is possible to style those elements using `Style.blockProperties`.

@docs div, header, footer, nav, section, article, aside, h1, h2, h3, h4, h5, h6, p


# Embed

@docs embed

-}

import BodyBuilder.Attributes exposing (..)
import BodyBuilder.Internals.Convert
import BodyBuilder.Internals.Shared as Shared
import Browser
import Elegant
import Elegant.Display as Display
import Elegant.Flex as Flex exposing (FlexContainerDetails)
import Elegant.Grid as Grid
import Function
import Html exposing (Html)
import Html.Attributes
import List.Extra
import Modifiers exposing (..)


{-| The main type of BodyBuilder. It is an alias to Html, in order to keep
perfect backward compatibility.
-}
type alias Node msg =
    Html msg


{-| The type of the flex items. A flex container contains only specific items.
Those are represented by this type. They're generated by the flexItem function,
to be used exclusively in flex.
-}
type FlexItem msg
    = FlexItem (NodeWithStyle msg)


extractNodeInFlexItem : FlexItem msg -> NodeWithStyle msg
extractNodeInFlexItem (FlexItem item) =
    item


{-| The type of the grid items. A grid container contains only specific items.
Those are represented by this type. They're generated by the gridItem function,
to be used exclusively in grid.
-}
type GridItem msg
    = GridItem (NodeWithStyle msg)


extractNodeInGridItem : GridItem msg -> NodeWithStyle msg
extractNodeInGridItem (GridItem item) =
    item


{-| Represents the different options used in select items. They're generated by
the option function, exclusively to be used in select.
-}
type Option msg
    = Option (NodeWithStyle msg)


extractOption : Option msg -> NodeWithStyle msg
extractOption (Option option_) =
    option_


{-| Puts plain text in the DOM. You can't set any attributes or events on it.
-}
text : String -> NodeWithStyle msg
text content =
    ( Html.text content, [] )


{-| Don't create anything in the DOM. This is useful when you have a conditionnal
and are forced to return a Node.

    textOrNone : Maybe String -> NodeWithStyle msg
    textOrNone value =
        case value of
            Nothing ->
                BodyBuilder.none

            Just content ->
                BodyBuilder.text content

-}
none : NodeWithStyle msg
none =
    text ""


{-| Puts a br in the DOM. You can't set any attributes or events on it, since
you want br to insert a carriage return.
-}
br : NodeWithStyle msg
br =
    ( Html.br [] [], [] )


stylise view_ e =
    let
        ( viewWithoutStyle, styles ) =
            view_ e
    in
    Html.div []
        (Html.node "style"
            []
            [ Html.text
                (String.join "\n"
                    (styles |> List.Extra.unique)
                )
            ]
            :: [ viewWithoutStyle ]
        )


{-| Creates a program, like you could with Html. This allows you to completely
overrides Html to focus on BodyBuilder.
-}
embed :
    { init : flags -> ( model, Cmd msg )
    , subscriptions : model -> Sub msg
    , update : msg -> model -> ( model, Cmd msg )
    , view : model -> NodeWithStyle msg
    }
    -> Program flags model msg
embed el =
    Browser.embed
        { init = el.init
        , subscriptions = el.subscriptions
        , update = el.update
        , view =
            \e ->
                stylise el.view e
        }


staticPage : NodeWithStyle msg -> Program () () msg
staticPage el =
    Browser.staticPage (stylise (\_ -> el) ())


inlineNode : String -> Modifiers (NodeAttributes msg) -> List (NodeWithStyle msg) -> NodeWithStyle msg
inlineNode tagName =
    commonBlockFlexlessNode
        tagName
        BodyBuilder.Attributes.defaultNodeAttributes
        BodyBuilder.Attributes.nodeAttributesToHtmlAttributes


{-| Generates an empty inline node in the DOM. A node is inline by default, but
changes its behavior when specifically set as block. You don't have to worry about
the display: use a node whenever you want, style like you want, it will adapt to
what you wrote.

    inlineElement : NodeWithStyle msg
    inlineElement =
        -- This produces an inline node in the DOM.
        BodyBuilder.node [] []

    blockElement : NodeWithStyle msg
    blockElement =
        -- This produces a block node in the DOM.
        BodyBuilder.node [ BodyBuilder.Attributes.style [ Style.block [] ] ] []

-}
node : Modifiers (NodeAttributes msg) -> List (NodeWithStyle msg) -> NodeWithStyle msg
node =
    inlineNode "bb-node"


{-| For backward compatibilty. It behaves like node, but avoids to rewrote all your
code when switching to BodyBuilder.
-}
span : Modifiers (NodeAttributes msg) -> List (NodeWithStyle msg) -> NodeWithStyle msg
span =
    inlineNode "span"


{-| Generates an inline flex in the DOM. A flex is inline by default, but
changes its behavior when specifically set as block. You don't have to worry about
the display: use a flex whenever you want, style like you want, it will adapt to
what you wrote.

    inlineFlex : NodeWithStyle msg
    inlineFlex =
        -- This produces an inline flex in the DOM.
        BodyBuilder.flex [] []

    blockFlex : NodeWithStyle msg
    blockFlex =
        -- This produces a block flex in the DOM.
        BodyBuilder.flex [ BodyBuilder.Attributes.style [ Style.block [] ] ] []

-}
flex : Modifiers (FlexContainerAttributes msg) -> List (FlexItem msg) -> NodeWithStyle msg
flex =
    commonNode
        "bb-flex"
        BodyBuilder.Attributes.defaultFlexContainerAttributes
        (List.map extractNodeInFlexItem)
        (.flexContainerProperties >> Just)
        nothingAttributes
        nothingAttributes
        nothingAttributes
        .block
        BodyBuilder.Attributes.flexContainerAttributesToHtmlAttributes


{-| Generates a flexItem in the DOM. A flexItem is only used inside flex, and
can contains the specific styling of the flexChildren.

    flexElement : NodeWithStyle msg
    flexElement =
        BodyBuilder.flex []
            [ BodyBuilder.flexItem []
                [ Html.text "I'm inside a flex-item!" ]
            ]

-}
flexItem : Modifiers (FlexItemAttributes msg) -> List (NodeWithStyle msg) -> FlexItem msg
flexItem modifiers =
    FlexItem
        << commonNode
            "bb-flex-item"
            BodyBuilder.Attributes.defaultFlexItemAttributes
            identity
            nothingAttributes
            (.flexItemProperties >> Just)
            nothingAttributes
            nothingAttributes
            .block
            BodyBuilder.Attributes.flexItemAttributesToHtmlAttributes
            modifiers


{-| Generates an inline grid in the DOM. A grid is inline by default, but
changes its behavior when specifically set as block. You don't have to worry about
the display: use a grid whenever you want, style like you want, it will adapt to
what you wrote.

    inlineGrid : NodeWithStyle msg
    inlineGrid =
        -- This produces an inline grid in the DOM.
        BodyBuilder.grid [] []

    blockGrid : NodeWithStyle msg
    blockGrid =
        -- This produces a block grid in the DOM.
        BodyBuilder.grid [ BodyBuilder.Attributes.style [ Style.block [] ] ] []

-}
grid : Modifiers (GridContainerAttributes msg) -> List (GridItem msg) -> NodeWithStyle msg
grid =
    commonNode
        "bb-grid"
        BodyBuilder.Attributes.defaultGridContainerAttributes
        (List.map extractNodeInGridItem)
        nothingAttributes
        nothingAttributes
        (.gridContainerProperties >> Just)
        nothingAttributes
        .block
        BodyBuilder.Attributes.gridContainerAttributesToHtmlAttributes


{-| Generates a gridItem in the DOM. A gridItem is only used inside grid, and
can contains the specific styling of the gridChildren.

    gridElement : NodeWithStyle msg
    gridElement =
        BodyBuilder.grid []
            [ BodyBuilder.gridItem []
                [ Html.text "I'm inside a grid-item!" ]
            ]

-}
gridItem : Modifiers (GridItemAttributes msg) -> List (NodeWithStyle msg) -> GridItem msg
gridItem modifiers =
    GridItem
        << commonNode
            "bb-grid-item"
            BodyBuilder.Attributes.defaultGridItemAttributes
            identity
            nothingAttributes
            nothingAttributes
            nothingAttributes
            (.gridItemProperties >> Just)
            .block
            BodyBuilder.Attributes.gridItemAttributesToHtmlAttributes
            modifiers


{-| Generates a link in the DOM. A link is inline by default, but
changes its behavior when specifically set as block. You don't have to worry about
the display: use an a whenever you want, style like you want, it will adapt to
what you wrote.

    inlineLink : NodeWithStyle msg
    inlineLink =
        -- This produces an inline a in the DOM.
        BodyBuilder.a [] []

    blockLink : NodeWithStyle msg
    blockLink =
        -- This produces a block a in the DOM.
        BodyBuilder.a [ BodyBuilder.Attributes.style [ Style.block [] ] ] []

-}
a : Modifiers (AAttributes msg) -> List (NodeWithStyle msg) -> NodeWithStyle msg
a =
    commonBlockFlexlessNode
        "a"
        BodyBuilder.Attributes.defaultAAttributes
        BodyBuilder.Attributes.aAttributesToHtmlAttributes


{-| Generates an image in the DOM. An image is inline by default, but
changes its behavior when specifically set as block. You don't have to worry about
the display: use an img whenever you want, style like you want, it will adapt to
what you wrote.

    inlineImage : NodeWithStyle msg
    inlineImage =
        -- This produces an inline img in the DOM.
        BodyBuilder.img [] []

    blockImage : NodeWithStyle msg
    blockImage =
        -- This produces a block img in the DOM.
        BodyBuilder.img [ BodyBuilder.Attributes.style [ Style.block [] ] ] []

-}
img : String -> String -> Modifiers (ImgAttributes msg) -> NodeWithStyle msg
img alt src =
    commonBlockFlexlessChildlessNode
        "img"
        (BodyBuilder.Attributes.defaultImgAttributes alt src)
        BodyBuilder.Attributes.imgAttributesToHtmlAttributes


{-| Generates an audio in the DOM. An audio is inline by default, but
changes its behavior when specifically set as block. You don't have to worry about
the display: use an audio whenever you want, style like you want, it will adapt to
what you wrote.

    inlineAudio : NodeWithStyle msg
    inlineAudio =
        -- This produces an inline audio in the DOM.
        BodyBuilder.audio [] []

    blockAudio : NodeWithStyle msg
    blockAudio =
        -- This produces a block audio in the DOM.
        BodyBuilder.audio [ BodyBuilder.Attributes.style [ Style.block [] ] ] []

-}
audio : Modifiers (AudioAttributes msg) -> NodeWithStyle msg
audio =
    commonBlockFlexlessChildlessNode
        "audio"
        BodyBuilder.Attributes.defaultAudioAttributes
        BodyBuilder.Attributes.audioAttributesToHtmlAttributes


{-| Generates a progress in the DOM. A progress is inline by default, but
changes its behavior when specifically set as block. You don't have to worry about
the display: use an progress whenever you want, style like you want, it will adapt to
what you wrote.

    inlineProgress : NodeWithStyle msg
    inlineProgress =
        -- This produces an inline progress in the DOM.
        BodyBuilder.progress [] []

    blockProgress : NodeWithStyle msg
    blockProgress =
        -- This produces a block progress in the DOM.
        BodyBuilder.progress [ BodyBuilder.Attributes.style [ Style.block [] ] ] []

-}
progress : Modifiers (ProgressAttributes msg) -> NodeWithStyle msg
progress =
    commonBlockFlexlessChildlessNode
        "progress"
        BodyBuilder.Attributes.defaultProgressAttributes
        BodyBuilder.Attributes.progressAttributesToHtmlAttributes


{-| Generates a button in the DOM. A button is inline by default, but
changes its behavior when specifically set as block. You don't have to worry about
the display: use an button whenever you want, style like you want, it will adapt to
what you wrote.

    inlineButton : NodeWithStyle msg
    inlineButton =
        -- This produces an inline button in the DOM.
        BodyBuilder.button [] []

    blockButton : NodeWithStyle msg
    blockButton =
        -- This produces a block button in the DOM.
        BodyBuilder.button [ BodyBuilder.Attributes.style [ Style.block [] ] ] []

-}
button : Modifiers (ButtonAttributes msg) -> List (NodeWithStyle msg) -> NodeWithStyle msg
button =
    commonBlockFlexlessNode
        "button"
        BodyBuilder.Attributes.defaultButtonAttributes
        BodyBuilder.Attributes.buttonAttributesToHtmlAttributes


{-| Generates an hidden input in the DOM. An hidden input is not displayed in the DOM.

    hiddenInput : NodeWithStyle msg
    hiddenInput =
        -- This produces an hidden input in the DOM.
        BodyBuilder.inputHidden []

-}
inputHidden : Modifiers InputHiddenAttributes -> NodeWithStyle msg
inputHidden modifiers =
    ( Html.input
        (BodyBuilder.Attributes.defaultInputHiddenAttributes
            |> Function.compose modifiers
            |> BodyBuilder.Attributes.inputHiddenAttributesToHtmlAttributes
        )
        []
    , []
    )


{-| Generates a text input in the DOM. A text input is inline by default, but
changes its behavior when specifically set as block. You don't have to worry about
the display: use an inputText whenever you want, style like you want, it will adapt to
what you wrote.

    inlineTextInput : NodeWithStyle msg
    inlineTextInput =
        -- This produces an inline text input in the DOM.
        BodyBuilder.inputText [] []

    blockTextInput : NodeWithStyle msg
    blockTextInput =
        -- This produces a block text input in the DOM.
        BodyBuilder.inputText [ BodyBuilder.Attributes.style [ Style.block [] ] ] []

-}
inputText : Modifiers (InputTextAttributes msg) -> NodeWithStyle msg
inputText =
    inputAndLabel
        BodyBuilder.Attributes.defaultInputTextAttributes
        BodyBuilder.Attributes.inputTextAttributesToHtmlAttributes


{-| Generates a tel input in the DOM. A tel input is inline by default, but
changes its behavior when specifically set as block. You don't have to worry about
the display: use an inputTel whenever you want, style like you want, it will adapt to
what you wrote.

    inlineTelInput : NodeWithStyle msg
    inlineTelInput =
        -- This produces an inline tel input in the DOM.
        BodyBuilder.inputTel [] []

    blockTelInput : NodeWithStyle msg
    blockTelInput =
        -- This produces a block tel input in the DOM.
        BodyBuilder.inputTel [ BodyBuilder.Attributes.style [ Style.block [] ] ] []

-}
inputTel : Modifiers (InputTextAttributes msg) -> NodeWithStyle msg
inputTel =
    inputAndLabel
        BodyBuilder.Attributes.defaultInputTelAttributes
        BodyBuilder.Attributes.inputTextAttributesToHtmlAttributes


{-| Generates a password input in the DOM. A password input is inline by default, but
changes its behavior when specifically set as block. You don't have to worry about
the display: use an inputPassword whenever you want, style like you want, it will adapt to
what you wrote.

    inlinePasswordInput : NodeWithStyle msg
    inlinePasswordInput =
        -- This produces an inline password input in the DOM.
        BodyBuilder.inputPassword [] []

    blockPasswordInput : NodeWithStyle msg
    blockPasswordInput =
        -- This produces a block password input in the DOM.
        BodyBuilder.inputPassword [ BodyBuilder.Attributes.style [ Style.block [] ] ] []

-}
inputPassword : Modifiers (InputPasswordAttributes msg) -> NodeWithStyle msg
inputPassword =
    inputAndLabel
        BodyBuilder.Attributes.defaultInputPasswordAttributes
        BodyBuilder.Attributes.inputPasswordAttributesToHtmlAttributes


{-| Generates a range input in the DOM. A range input is inline by default, but
changes its behavior when specifically set as block. You don't have to worry about
the display: use an inputRange whenever you want, style like you want, it will adapt to
what you wrote.

    inlineRangeInput : NodeWithStyle msg
    inlineRangeInput =
        -- This produces an inline range input in the DOM.
        BodyBuilder.inputRange [] []

    blockRangeInput : NodeWithStyle msg
    blockRangeInput =
        -- This produces a block range input in the DOM.
        BodyBuilder.inputRange [ BodyBuilder.Attributes.style [ Style.block [] ] ] []

-}
inputRange : Modifiers (InputRangeAttributes msg) -> NodeWithStyle msg
inputRange =
    inputAndLabel
        BodyBuilder.Attributes.defaultInputRangeAttributes
        BodyBuilder.Attributes.inputRangeAttributesToHtmlAttributes


{-| Generates a number input in the DOM. A number input is inline by default, but
changes its behavior when specifically set as block. You don't have to worry about
the display: use an inputNumber whenever you want, style like you want, it will adapt to
what you wrote.

    inlineNumberInput : NodeWithStyle msg
    inlineNumberInput =
        -- This produces an inline number input in the DOM.
        BodyBuilder.inputNumber [] []

    blockNumberInput : NodeWithStyle msg
    blockNumberInput =
        -- This produces a block number input in the DOM.
        BodyBuilder.inputNumber [ BodyBuilder.Attributes.style [ Style.block [] ] ] []

-}
inputNumber : Modifiers (InputNumberAttributes msg) -> NodeWithStyle msg
inputNumber =
    inputAndLabel
        BodyBuilder.Attributes.defaultInputNumberAttributes
        BodyBuilder.Attributes.inputNumberAttributesToHtmlAttributes


{-| Generates a radio input in the DOM. A radio input is inline by default, but
changes its behavior when specifically set as block. You don't have to worry about
the display: use an inputRadio whenever you want, style like you want, it will adapt to
what you wrote.

    inlineRadioInput : NodeWithStyle msg
    inlineRadioInput =
        -- This produces an inline radio input in the DOM.
        BodyBuilder.inputRadio [] []

    blockRadioInput : NodeWithStyle msg
    blockRadioInput =
        -- This produces a block radio input in the DOM.
        BodyBuilder.inputRadio [ BodyBuilder.Attributes.style [ Style.block [] ] ] []

-}
inputRadio : Modifiers (InputRadioAttributes msg) -> NodeWithStyle msg
inputRadio =
    inputAndLabel
        BodyBuilder.Attributes.defaultInputRadioAttributes
        BodyBuilder.Attributes.inputRadioAttributesToHtmlAttributes


{-| Generates a checkbox input in the DOM. A checkbox input is inline by default, but
changes its behavior when specifically set as block. You don't have to worry about
the display: use an inputCheckbox whenever you want, style like you want, it will adapt to
what you wrote.

    inlineCheckboxInput : NodeWithStyle msg
    inlineCheckboxInput =
        -- This produces an inline checkbox input in the DOM.
        BodyBuilder.inputCheckbox [] []

    blockCheckboxInput : NodeWithStyle msg
    blockCheckboxInput =
        -- This produces a block checkbox input in the DOM.
        BodyBuilder.inputCheckbox [ BodyBuilder.Attributes.style [ Style.block [] ] ] []

-}
inputCheckbox : Modifiers (InputCheckboxAttributes msg) -> NodeWithStyle msg
inputCheckbox =
    inputAndLabel
        BodyBuilder.Attributes.defaultInputCheckboxAttributes
        BodyBuilder.Attributes.inputCheckboxAttributesToHtmlAttributes


{-| Generates a submit input in the DOM. A submit input is inline by default, but
changes its behavior when specifically set as block. You don't have to worry about
the display: use an inputSubmit whenever you want, style like you want, it will adapt to
what you wrote.

    inlineSubmitInput : NodeWithStyle msg
    inlineSubmitInput =
        -- This produces an inline submit input in the DOM.
        BodyBuilder.inputSubmit [] []

    blockSubmitInput : NodeWithStyle msg
    blockSubmitInput =
        -- This produces a block submit input in the DOM.
        BodyBuilder.inputSubmit [ BodyBuilder.Attributes.style [ Style.block [] ] ] []

-}
inputSubmit : Modifiers (InputSubmitAttributes msg) -> NodeWithStyle msg
inputSubmit =
    inputAndLabel
        BodyBuilder.Attributes.defaultInputSubmitAttributes
        BodyBuilder.Attributes.inputSubmitAttributesToHtmlAttributes


{-| Generates an url input in the DOM. An url input is inline by default, but
changes its behavior when specifically set as block. You don't have to worry about
the display: use an inputUrl whenever you want, style like you want, it will adapt to
what you wrote.

    inlineUrlInput : NodeWithStyle msg
    inlineUrlInput =
        -- This produces an inline url input in the DOM.
        BodyBuilder.inputUrl [] []

    blockUrlInput : NodeWithStyle msg
    blockUrlInput =
        -- This produces a block url input in the DOM.
        BodyBuilder.inputUrl [ BodyBuilder.Attributes.style [ Style.block [] ] ] []

-}
inputUrl : Modifiers (InputUrlAttributes msg) -> NodeWithStyle msg
inputUrl =
    inputAndLabel
        BodyBuilder.Attributes.defaultInputUrlAttributes
        BodyBuilder.Attributes.inputUrlAttributesToHtmlAttributes


{-| Generates a color input in the DOM. A color input is inline by default, but
changes its behavior when specifically set as block. You don't have to worry about
the display: use an inputColor whenever you want, style like you want, it will adapt to
what you wrote.

    inlineColorInput : NodeWithStyle msg
    inlineColorInput =
        -- This produces an inline color input in the DOM.
        BodyBuilder.inputColor [] []

    blockColorInput : NodeWithStyle msg
    blockColorInput =
        -- This produces a block color input in the DOM.
        BodyBuilder.inputColor [ BodyBuilder.Attributes.style [ Style.block [] ] ] []

-}
inputColor : Modifiers (InputColorAttributes msg) -> NodeWithStyle msg
inputColor =
    inputAndLabel
        BodyBuilder.Attributes.defaultInputColorAttributes
        BodyBuilder.Attributes.inputColorAttributesToHtmlAttributes


{-| Generates a file input in the DOM. A file input is inline by default, but
changes its behavior when specifically set as block. You don't have to worry about
the display: use an inputFile whenever you want, style like you want, it will adapt to
what you wrote.

    inlineFileInput : NodeWithStyle msg
    inlineFileInput =
        -- This produces an inline file input in the DOM.
        BodyBuilder.inputFile [] []

    blockFileInput : NodeWithStyle msg
    blockFileInput =
        -- This produces a block file input in the DOM.
        BodyBuilder.inputFile [ BodyBuilder.Attributes.style [ Style.block [] ] ] []

-}
inputFile : Modifiers (InputFileAttributes msg) -> NodeWithStyle msg
inputFile =
    inputAndLabel
        BodyBuilder.Attributes.defaultInputFileAttributes
        BodyBuilder.Attributes.inputFileAttributesToHtmlAttributes


{-| Generates a textarea in the DOM. A textarea is inline by default, but
changes its behavior when specifically set as block. You don't have to worry about
the display: use an textarea whenever you want, style like you want, it will adapt to
what you wrote.

    inlineTextarea : NodeWithStyle msg
    inlineTextarea =
        -- This produces an inline textarea in the DOM.
        BodyBuilder.textarea [] []

    blockTextarea : NodeWithStyle msg
    blockTextarea =
        -- This produces a block textarea in the DOM.
        BodyBuilder.textarea [ BodyBuilder.Attributes.style [ Style.block [] ] ] []

-}
textarea : Modifiers (TextareaAttributes msg) -> NodeWithStyle msg
textarea =
    commonBlockFlexlessChildlessNode
        "textarea"
        BodyBuilder.Attributes.defaultTextareaAttributes
        BodyBuilder.Attributes.textareaAttributesToHtmlAttributes


{-| Generates a select in the DOM. A select is inline by default, but
changes its behavior when specifically set as block. You don't have to worry about
the display: use a select whenever you want, style like you want, it will adapt to
what you wrote.

    inlineSelect : NodeWithStyle msg
    inlineSelect =
        -- This produces an inline select in the DOM.
        BodyBuilder.select [] []

    blockSelect : NodeWithStyle msg
    blockSelect =
        -- This produces a block select in the DOM.
        BodyBuilder.select [ BodyBuilder.Attributes.style [ Style.block [] ] ] []

-}
select : Modifiers (SelectAttributes msg) -> List (Option msg) -> NodeWithStyle msg
select =
    commonNode
        "select"
        BodyBuilder.Attributes.defaultSelectAttributes
        (List.map extractOption)
        nothingAttributes
        nothingAttributes
        nothingAttributes
        nothingAttributes
        .block
        BodyBuilder.Attributes.selectAttributesToHtmlAttributes


{-| Generates an option in the DOM. An option is only used inside select, and
constituted of to String: the value and the content. It can also be selected, or not.

    selectElement : NodeWithStyle msg
    selectElement =
        BodyBuilder.select []
            [ BodyBuilder.option "Paris" "We're in Paris!" True
            , BodyBuilder.option "London" "We're in London!" False
            , BodyBuilder.option "Berlin" "We're in Berlin!" False
            ]

-}
option : String -> String -> Bool -> Option msg
option value content selected =
    Option <|
        ( Html.option
            [ Html.Attributes.value value
            , Html.Attributes.selected selected
            ]
            [ Html.text content ]
        , []
        )


heading : String -> Modifiers (HeadingAttributes msg) -> List (NodeWithStyle msg) -> NodeWithStyle msg
heading tag =
    commonNode
        tag
        BodyBuilder.Attributes.defaultHeadingAttributes
        identity
        nothingAttributes
        nothingAttributes
        nothingAttributes
        nothingAttributes
        (.block >> Just)
        BodyBuilder.Attributes.headingAttributesToHtmlAttributes


{-| Generates an h1 in the DOM. An h1 is block, and can't be anything else.
You can add custom block style on it, but can't turn it inline.

    title : NodeWithStyle msg
    title =
        BodyBuilder.h1
            [ BodyBuilder.Attributes.style [ Style.blockProperties [] ] ]
            [ Html.text "I'm inside a title!" ]

-}
h1 : Modifiers (HeadingAttributes msg) -> List (NodeWithStyle msg) -> NodeWithStyle msg
h1 =
    heading "h1"


{-| Generates an h2 in the DOM. An h2 is block, and can't be anything else.
You can add custom block style on it, but can't turn it inline.

    title : NodeWithStyle msg
    title =
        BodyBuilder.h2
            [ BodyBuilder.Attributes.style [ Style.blockProperties [] ] ]
            [ Html.text "I'm inside a title!" ]

-}
h2 : Modifiers (HeadingAttributes msg) -> List (NodeWithStyle msg) -> NodeWithStyle msg
h2 =
    heading "h2"


{-| Generates an h3 in the DOM. An h3 is block, and can't be anything else.
You can add custom block style on it, but can't turn it inline.

    title : NodeWithStyle msg
    title =
        BodyBuilder.h3
            [ BodyBuilder.Attributes.style [ Style.blockProperties [] ] ]
            [ Html.text "I'm inside a title!" ]

-}
h3 : Modifiers (HeadingAttributes msg) -> List (NodeWithStyle msg) -> NodeWithStyle msg
h3 =
    heading "h3"


{-| Generates an h4 in the DOM. An h4 is block, and can't be anything else.
You can add custom block style on it, but can't turn it inline.

    title : NodeWithStyle msg
    title =
        BodyBuilder.h4
            [ BodyBuilder.Attributes.style [ Style.blockProperties [] ] ]
            [ Html.text "I'm inside a title!" ]

-}
h4 : Modifiers (HeadingAttributes msg) -> List (NodeWithStyle msg) -> NodeWithStyle msg
h4 =
    heading "h4"


{-| Generates an h5 in the DOM. An h5 is block, and can't be anything else.
You can add custom block style on it, but can't turn it inline.

    title : NodeWithStyle msg
    title =
        BodyBuilder.h5
            [ BodyBuilder.Attributes.style [ Style.blockProperties [] ] ]
            [ Html.text "I'm inside a title!" ]

-}
h5 : Modifiers (HeadingAttributes msg) -> List (NodeWithStyle msg) -> NodeWithStyle msg
h5 =
    heading "h5"


{-| Generates an h6 in the DOM. An h6 is block, and can't be anything else.
You can add custom block style on it, but can't turn it inline.

    title : NodeWithStyle msg
    title =
        BodyBuilder.h6
            [ BodyBuilder.Attributes.style [ Style.blockProperties [] ] ]
            [ Html.text "I'm inside a title!" ]

-}
h6 : Modifiers (HeadingAttributes msg) -> List (NodeWithStyle msg) -> NodeWithStyle msg
h6 =
    heading "h6"


{-| Generates a p in the DOM. A p is block, and can't be anything else.
You can add custom block style on it, but can't turn it inline.

    title : NodeWithStyle msg
    title =
        BodyBuilder.p
            [ BodyBuilder.Attributes.style [ Style.blockProperties [] ] ]
            [ Html.text "I'm inside a paragrah!" ]

-}
p : Modifiers (HeadingAttributes msg) -> List (NodeWithStyle msg) -> NodeWithStyle msg
p =
    heading "p"


{-| Represents the attributes for a block element, i.e. an element which can't be
anything else other than a block. This includes titles, paragraph, section, nav,
article, aside, footer, header and div. This element have to use `Style.blockProperties`
to set style on them.
-}
type alias BlockAttributes msg =
    HeadingAttributes msg


block :
    String
    -> Modifiers (HeadingAttributes msg)
    -> List (NodeWithStyle msg)
    -> NodeWithStyle msg
block =
    heading


{-| For backward compatibilty. It behaves like div in Html.
-}
div : Modifiers (BlockAttributes msg) -> List (NodeWithStyle msg) -> NodeWithStyle msg
div =
    block "div"


{-| Generates the corresponding section in the DOM. This is used mainly to respect
the HTML semantic and for accessibility.
-}
section : Modifiers (BlockAttributes msg) -> List (NodeWithStyle msg) -> NodeWithStyle msg
section =
    block "section"


{-| Generates the corresponding nav in the DOM. This is used mainly to respect
the HTML semantic and for accessibility.
-}
nav : Modifiers (BlockAttributes msg) -> List (NodeWithStyle msg) -> NodeWithStyle msg
nav =
    block "nav"


{-| Generates the corresponding article in the DOM. This is used mainly to respect
the HTML semantic and for accessibility.
-}
article : Modifiers (BlockAttributes msg) -> List (NodeWithStyle msg) -> NodeWithStyle msg
article =
    block "article"


{-| Generates the corresponding aside in the DOM. This is used mainly to respect
the HTML semantic and for accessibility.
-}
aside : Modifiers (BlockAttributes msg) -> List (NodeWithStyle msg) -> NodeWithStyle msg
aside =
    block "aside"


{-| Generates the corresponding footer in the DOM. This is used mainly to respect
the HTML semantic and for accessibility.
-}
footer : Modifiers (BlockAttributes msg) -> List (NodeWithStyle msg) -> NodeWithStyle msg
footer =
    block "footer"


{-| Generates the corresponding header in the DOM. This is used mainly to respect
the HTML semantic and for accessibility.
-}
header : Modifiers (BlockAttributes msg) -> List (NodeWithStyle msg) -> NodeWithStyle msg
header =
    block "header"



-- Internals


commonNode :
    String
    -> VisibleAttributes a
    -> (b -> List (NodeWithStyle msg))
    -> (VisibleAttributes a -> Maybe (List ( Modifiers Flex.FlexContainerDetails, StyleSelector )))
    -> (VisibleAttributes a -> Maybe (List ( Modifiers Flex.FlexItemDetails, StyleSelector )))
    -> (VisibleAttributes a -> Maybe (List ( Modifiers Grid.GridContainerDetails, StyleSelector )))
    -> (VisibleAttributes a -> Maybe (List ( Modifiers Grid.GridItemDetails, StyleSelector )))
    -> (VisibleAttributes a -> Maybe (List ( Modifiers Display.BlockDetails, StyleSelector )))
    -> (VisibleAttributes a -> List (Html.Attribute msg))
    -> Modifiers (VisibleAttributes a)
    -> b
    -> NodeWithStyle msg
commonNode nodeName defaultAttributes childrenModifiers getFlexContainerProperties getFlexItemProperties getGridContainerProperties getGridItemProperties getBlockProperties attributesToHtmlAttributes modifiers children =
    computeBlock
        nodeName
        getFlexContainerProperties
        getFlexItemProperties
        getGridContainerProperties
        getGridItemProperties
        getBlockProperties
        defaultAttributes
        attributesToHtmlAttributes
        modifiers
        (childrenModifiers children)


commonChildlessNode :
    String
    -> VisibleAttributes a
    -> (List b -> List (NodeWithStyle msg))
    -> (VisibleAttributes a -> Maybe (List ( Modifiers Flex.FlexContainerDetails, StyleSelector )))
    -> (VisibleAttributes a -> Maybe (List ( Modifiers Flex.FlexItemDetails, StyleSelector )))
    -> (VisibleAttributes a -> Maybe (List ( Modifiers Grid.GridContainerDetails, StyleSelector )))
    -> (VisibleAttributes a -> Maybe (List ( Modifiers Grid.GridItemDetails, StyleSelector )))
    -> (VisibleAttributes a -> Maybe (List ( Modifiers Display.BlockDetails, StyleSelector )))
    -> (VisibleAttributes a -> List (Html.Attribute msg))
    -> Modifiers (VisibleAttributes a)
    -> NodeWithStyle msg
commonChildlessNode nodeName defaultAttributes childrenModifiers getFlexContainerProperties getFlexItemProperties getGridContainerProperties getGridItemProperties getBlockProperties attributesToHtmlAttributes =
    Function.flip
        (commonNode
            nodeName
            defaultAttributes
            childrenModifiers
            getFlexContainerProperties
            getFlexItemProperties
            getGridContainerProperties
            getGridItemProperties
            getBlockProperties
            attributesToHtmlAttributes
        )
        []


commonBlockFlexlessNode :
    String
    -> VisibleAttributes (MaybeBlockContainer a)
    -> (VisibleAttributes (MaybeBlockContainer a) -> List (Html.Attribute msg))
    -> Modifiers (VisibleAttributes (MaybeBlockContainer a))
    -> List (NodeWithStyle msg)
    -> NodeWithStyle msg
commonBlockFlexlessNode tag defaultAttributes convertAttributes =
    commonNode
        tag
        defaultAttributes
        identity
        nothingAttributes
        nothingAttributes
        nothingAttributes
        nothingAttributes
        .block
        convertAttributes


commonBlockFlexlessChildlessNode :
    String
    -> VisibleAttributes (MaybeBlockContainer a)
    -> (VisibleAttributes (MaybeBlockContainer a) -> List (Html.Attribute msg))
    -> Modifiers (VisibleAttributes (MaybeBlockContainer a))
    -> NodeWithStyle msg
commonBlockFlexlessChildlessNode tag defaultAttributes convertAttributes =
    commonChildlessNode
        tag
        defaultAttributes
        identity
        nothingAttributes
        nothingAttributes
        nothingAttributes
        nothingAttributes
        .block
        convertAttributes


nothingAttributes : b -> Maybe a
nothingAttributes _ =
    Nothing


inputAndLabel :
    MaybeBlockContainer (VisibleAttributes { a | label : Maybe (Shared.Label msg) })
    -> (MaybeBlockContainer (VisibleAttributes { a | label : Maybe (Shared.Label msg) }) -> List (Html.Attribute msg))
    -> Modifiers (MaybeBlockContainer (VisibleAttributes { a | label : Maybe (Shared.Label msg) }))
    -> NodeWithStyle msg
inputAndLabel defaultAttributes attributesToHtmlAttributes modifiers =
    let
        attributes =
            Function.compose modifiers
                defaultAttributes

        styles =
            BodyBuilder.Internals.Convert.toElegantStyle
                Nothing
                Nothing
                Nothing
                Nothing
                attributes.block
                attributes.box
                |> List.concatMap Elegant.styleToCss

        computedInput =
            Html.input
                (styles
                    |> List.map Tuple.first
                    |> String.join " "
                    |> Html.Attributes.class
                    |> Function.flip (::) (attributesToHtmlAttributes attributes)
                )
                []
    in
    case attributes.label of
        Nothing ->
            ( computedInput
            , styles
                |> List.map Tuple.second
            )

        Just label ->
            ( Shared.extractLabel label computedInput, [] )


computeBlock :
    String
    -> (VisibleAttributes a -> Maybe (List ( Modifiers Flex.FlexContainerDetails, StyleSelector )))
    -> (VisibleAttributes a -> Maybe (List ( Modifiers Flex.FlexItemDetails, StyleSelector )))
    -> (VisibleAttributes a -> Maybe (List ( Modifiers Grid.GridContainerDetails, StyleSelector )))
    -> (VisibleAttributes a -> Maybe (List ( Modifiers Grid.GridItemDetails, StyleSelector )))
    -> (VisibleAttributes a -> Maybe (List ( Modifiers Display.BlockDetails, StyleSelector )))
    -> VisibleAttributes a
    -> (VisibleAttributes a -> List (Html.Attribute msg))
    -> Modifiers (VisibleAttributes a)
    -> List (NodeWithStyle msg)
    -> NodeWithStyle msg
computeBlock tag flexModifiers flexItemModifiers gridModifiers gridItemModifiers blockModifiers defaultAttributes attributesToHtmlAttributes modifiers content =
    let
        attributes =
            Function.compose modifiers
                defaultAttributes

        styleResult =
            BodyBuilder.Internals.Convert.toElegantStyle
                (flexModifiers attributes)
                (flexItemModifiers attributes)
                (gridModifiers attributes)
                (gridItemModifiers attributes)
                (blockModifiers attributes)
                attributes.box
                |> List.concatMap Elegant.styleToCss
    in
    ( Html.node tag
        (styleResult
            |> List.map Tuple.first
            |> String.join " "
            |> Html.Attributes.class
            |> Function.flip (::) (attributesToHtmlAttributes attributes)
        )
        (content
            |> List.map Tuple.first
        )
    , (styleResult |> List.map Tuple.second) ++ (content |> List.map Tuple.second |> List.concat)
    )


type alias NodeWithStyle msg =
    ( Node msg, List String )
