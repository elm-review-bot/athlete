module Display exposing (..)

import Either exposing (Either(..))
import Helpers.Css
import Maybe.Extra
import Layout
import Helpers.Shared exposing (..)
import Helpers.Setters exposing (..)
import Display.Overflow as Overflow


-- Display


type DisplayBox
    = None
    | ContentsWrapper Contents


type alias Contents =
    { outsideDisplay : OutsideDisplay
    , insideDisplay : InsideDisplay
    , maybeLayout : Maybe Layout.Layout
    }


type OutsideDisplay
    = Inline
    | Block (Maybe BlockDetails)
    | FlexItem (Maybe FlexItemDetails)


type InsideDisplay
    = Flow
    | FlexContainer (Maybe FlexContainerDetails)


displayBox : OutsideDisplay -> InsideDisplay -> Modifiers Layout.Layout -> DisplayBox
displayBox outsideDisplay insideDisplay =
    ContentsWrapper
        << Contents outsideDisplay insideDisplay
        << modifiedElementOrNothing Layout.default


{-| displayNone
The "display none" <display box> is useful to simply don't show
the element in the browser, it is on top of the hierarchy, because
applying any text or layout style to a "display none" element doesn't
mean anything.

    Display.none

-}
none : DisplayBox
none =
    None


{-| The display Block
node behaving like a block element
children behaving like inside a flow element => considered block from children

    Display.block
        [ dimensions [ width (px 30) ] ]
        [ Layout.padding (px 30) ]

-}
block : Modifiers BlockDetails -> Modifiers Layout.Layout -> DisplayBox
block blockDetailsModifiers =
    displayBox
        (Block (modifiedElementOrNothing defaultBlockDetails blockDetailsModifiers))
        Flow


{-| The display inline
node behaving like an inline element

    Display.inline
        [ Layout.background [ Elegant.color Color.blue ] ]

-}
inline : Modifiers Layout.Layout -> DisplayBox
inline =
    displayBox
        Inline
        Flow


{-| The display inline-flex container :
node behaving like an inline element, contained nodes will behave like flex children

    Display.inlineFlexContainer [] []

-}
inlineFlexContainer : Modifiers FlexContainerDetails -> Modifiers Layout.Layout -> DisplayBox
inlineFlexContainer flexContainerDetailsModifiers =
    displayBox
        Inline
        (FlexContainer (modifiedElementOrNothing defaultFlexContainerDetails flexContainerDetailsModifiers))


{-| The display blockflex container :
node behaving like an block element, contained nodes will behave like flex children

    Display.blockFlexContainer [] [] []

-}
blockFlexContainer : Modifiers FlexContainerDetails -> Modifiers BlockDetails -> Modifiers Layout.Layout -> DisplayBox
blockFlexContainer flexContainerDetailsModifiers blockDetailsModifiers =
    displayBox
        (Block (modifiedElementOrNothing defaultBlockDetails blockDetailsModifiers))
        (FlexContainer (modifiedElementOrNothing defaultFlexContainerDetails flexContainerDetailsModifiers))


{-| The display flexitemdetails container :
node behaving like an flex child (not being a flex father himself)

    Display.flexChild [] []

-}
flexChild : Modifiers FlexItemDetails -> Modifiers Layout.Layout -> DisplayBox
flexChild flexItemDetailsModifiers =
    displayBox
        (FlexItem (modifiedElementOrNothing defaultFlexItemDetails flexItemDetailsModifiers))
        Flow


{-| The display flexchildcontainer container :
node behaving like an flex child being a flex father himself.

    Display.flexChildContainer [] [] []

-}
flexChildContainer : Modifiers FlexContainerDetails -> Modifiers FlexItemDetails -> Modifiers Layout.Layout -> DisplayBox
flexChildContainer flexContainerDetailsModifiers flexItemDetailsModifiers =
    displayBox
        (FlexItem (modifiedElementOrNothing defaultFlexItemDetails flexItemDetailsModifiers))
        (FlexContainer (modifiedElementOrNothing defaultFlexContainerDetails flexContainerDetailsModifiers))


type alias BlockDetails =
    { listStyleType : Maybe ListStyleType
    , alignment : Maybe Alignment
    , overflow : Maybe Overflow.FullOverflow
    , textOverflow : Maybe TextOverflow
    , dimensions : Maybe Dimensions
    }


defaultBlockDetails : BlockDetails
defaultBlockDetails =
    BlockDetails Nothing Nothing Nothing Nothing Nothing


type ListStyleType
    = ListStyleTypeNone
    | ListStyleTypeDisc
    | ListStyleTypeCircle
    | ListStyleTypeSquare
    | ListStyleTypeDecimal
    | ListStyleTypeGeorgian


listStyleType : ListStyleType -> Modifier BlockDetails
listStyleType =
    setListStyleType << Just


listStyleNone : Modifier BlockDetails
listStyleNone =
    listStyleType ListStyleTypeNone


listStyleDisc : Modifier BlockDetails
listStyleDisc =
    listStyleType ListStyleTypeDisc


listStyleCircle : Modifier BlockDetails
listStyleCircle =
    listStyleType ListStyleTypeCircle


listStyleSquare : Modifier BlockDetails
listStyleSquare =
    listStyleType ListStyleTypeSquare


listStyleDecimal : Modifier BlockDetails
listStyleDecimal =
    listStyleType ListStyleTypeDecimal


listStyleGeorgian : Modifier BlockDetails
listStyleGeorgian =
    listStyleType ListStyleTypeGeorgian


type Alignment
    = AlignmentCenter
    | AlignmentRight
    | AlignmentLeft
    | AlignmentJustify


alignment : Alignment -> Modifier BlockDetails
alignment =
    setAlignment << Just


alignCenter : Modifier BlockDetails
alignCenter =
    alignment AlignmentCenter


right : Alignment
right =
    AlignmentRight


left : Alignment
left =
    AlignmentLeft


justify : Alignment
justify =
    AlignmentJustify


overflow : Modifiers Overflow.FullOverflow -> Modifier BlockDetails
overflow =
    getModifyAndSet .overflow setOverflowIn Overflow.default


type TextOverflow
    = TextOverflowEllipsis


textOverflowEllipsis : Modifier BlockDetails
textOverflowEllipsis =
    setTextOverflow <| Just TextOverflowEllipsis


type alias Dimensions =
    ( DimensionAxis, DimensionAxis )


defaultDimensions : ( DimensionAxis, DimensionAxis )
defaultDimensions =
    ( defaultDimensionAxis, defaultDimensionAxis )


type alias DimensionAxis =
    { min : Maybe SizeUnit
    , dimension : Maybe SizeUnit
    , max : Maybe SizeUnit
    }


defaultDimensionAxis : DimensionAxis
defaultDimensionAxis =
    DimensionAxis Nothing Nothing Nothing


dimensions : Modifiers Dimensions -> Modifier BlockDetails
dimensions =
    getModifyAndSet .dimensions setDimensionsIn defaultDimensions


{-| -}
width : SizeUnit -> Modifier Dimensions
width value ( x, y ) =
    ( x |> setDimension (Just value), y )


{-| -}
height : SizeUnit -> Modifier Dimensions
height value ( x, y ) =
    ( x, y |> setDimension (Just value) )


type alias FlexContainerDetails =
    { direction : Maybe FlexDirection
    , wrap : Maybe FlexWrap
    , align : Maybe Align
    , justifyContent : Maybe JustifyContent
    }


defaultFlexContainerDetails : FlexContainerDetails
defaultFlexContainerDetails =
    FlexContainerDetails Nothing Nothing Nothing Nothing


type FlexDirection
    = FlexDirectionColumn
    | FlexDirectionRow


direction : FlexDirection -> Modifier FlexContainerDetails
direction =
    setDirection << Just


column : FlexDirection
column =
    FlexDirectionColumn


row : FlexDirection
row =
    FlexDirectionRow


type FlexWrap
    = FlexWrapWrap
    | FlexWrapNoWrap


wrap : Modifier FlexContainerDetails
wrap =
    setWrap <| Just FlexWrapWrap


noWrap : Modifier FlexContainerDetails
noWrap =
    setWrap <| Just FlexWrapNoWrap


type Align
    = AlignBaseline
    | AlignCenter
    | AlignFlexStart
    | AlignFlexEnd
    | AlignInherit
    | AlignInitial
    | AlignStretch


align : Align -> Modifier FlexContainerDetails
align =
    setAlign << Just


baseline : Align
baseline =
    AlignBaseline


center : Align
center =
    AlignCenter


flexStart : Align
flexStart =
    AlignFlexStart


flexEnd : Align
flexEnd =
    AlignFlexEnd


inherit : Align
inherit =
    AlignInherit


initial : Align
initial =
    AlignInitial


stretch : Align
stretch =
    AlignStretch


type JustifyContent
    = JustifyContentSpaceBetween
    | JustifyContentSpaceAround
    | JustifyContentCenter


justifyContent : JustifyContent -> Modifier FlexContainerDetails
justifyContent =
    setJustifyContent << Just


spaceBetween : JustifyContent
spaceBetween =
    JustifyContentSpaceBetween


spaceAround : JustifyContent
spaceAround =
    JustifyContentSpaceAround


justifyContentCenter : JustifyContent
justifyContentCenter =
    JustifyContentCenter


type alias FlexItemDetails =
    { grow : Maybe Int
    , shrink : Maybe Int
    , basis : Maybe (Either SizeUnit Auto)
    , alignSelf : Maybe Align
    }


defaultFlexItemDetails : FlexItemDetails
defaultFlexItemDetails =
    FlexItemDetails Nothing Nothing Nothing Nothing


grow : Int -> Modifier FlexItemDetails
grow =
    setGrow << Just


shrink : Int -> Modifier FlexItemDetails
shrink =
    setShrink << Just


basisAuto : Modifier FlexItemDetails
basisAuto =
    setBasis <| Just <| Right Auto


basis : SizeUnit -> Modifier FlexItemDetails
basis =
    setBasis << Just << Left


alignSelf : Align -> Modifier FlexItemDetails
alignSelf =
    setAlignSelf << Just



-- Internals


displayBoxToCouples : Maybe DisplayBox -> List ( String, String )
displayBoxToCouples =
    unwrapEmptyList extractDisplayBoxCouples


extractDisplayBoxCouples : DisplayBox -> List ( String, String )
extractDisplayBoxCouples val =
    case val of
        None ->
            [ ( "display", "none" ) ]

        ContentsWrapper { outsideDisplay, insideDisplay, maybeLayout } ->
            outsideInsideDisplayToCouples outsideDisplay insideDisplay
                ++ (maybeLayout |> Maybe.map Layout.layoutToCouples |> Maybe.withDefault [])


outsideInsideDisplayToCouples : OutsideDisplay -> InsideDisplay -> List ( String, String )
outsideInsideDisplayToCouples outsideDisplay insideDisplay =
    let
        ( dis, rest ) =
            outsideDisplayToCouples outsideDisplay
                |> Helpers.Css.joiner (insideDisplayToCouples insideDisplay)
    in
        [ ( "display", dis |> toLegacyDisplayCss ) ] ++ rest


outsideDisplayToCouples : OutsideDisplay -> ( String, List ( String, String ) )
outsideDisplayToCouples outsideDisplay =
    case outsideDisplay of
        Inline ->
            ( "inline", [] )

        Block blockDetails ->
            ( "block", maybeBlockDetailsToString blockDetails )

        FlexItem flexItemDetails ->
            ( "block", flexItemDetailsToString flexItemDetails )


insideDisplayToCouples : InsideDisplay -> ( String, List ( String, String ) )
insideDisplayToCouples insideDisplay =
    case insideDisplay of
        Flow ->
            ( "flow", [] )

        FlexContainer flexContainerDetails ->
            ( "flex", flexContainerDetailsToString flexContainerDetails )


dimensionsToString : Dimensions -> List ( String, String )
dimensionsToString size =
    [ ( "width", Tuple.first >> .dimension )
    , ( "min-width", Tuple.first >> .min )
    , ( "max-width", Tuple.first >> .max )
    , ( "height", Tuple.second >> .dimension )
    , ( "max-height", Tuple.second >> .max )
    , ( "min-height", Tuple.second >> .min )
    ]
        |> List.map (Tuple.mapSecond (callOn size))
        |> List.concatMap keepJustValues
        |> List.map (Tuple.mapSecond sizeUnitToString)


keepJustValues : ( String, Maybe a ) -> List ( String, a )
keepJustValues ( property, value ) =
    case value of
        Nothing ->
            []

        Just val ->
            [ ( property, val ) ]


maybeDimensionsToString : Maybe Dimensions -> List ( String, String )
maybeDimensionsToString =
    unwrapEmptyList dimensionsToString


blockDetailsToString : BlockDetails -> List ( String, String )
blockDetailsToString blockDetails =
    []


maybeBlockDetailsToString : Maybe BlockDetails -> List ( String, String )
maybeBlockDetailsToString =
    unwrapEmptyList blockDetailsToString


flexContainerDetailsToString : a -> List b
flexContainerDetailsToString flexContainerDetails =
    []


flexItemDetailsToString : a -> List b
flexItemDetailsToString flexContainerDetails =
    []


layoutStyleToString : a -> List b
layoutStyleToString a =
    []


toLegacyDisplayCss : String -> String
toLegacyDisplayCss str =
    case str of
        "inline flow" ->
            "inline"

        "inline flex" ->
            "inline-flex"

        "block flow" ->
            "block"

        "block flex" ->
            "flex"

        str ->
            str


alignItemsToString : Maybe Align -> Maybe String
alignItemsToString =
    nothingOrJust
        (\val ->
            case val of
                AlignBaseline ->
                    "baseline"

                AlignCenter ->
                    "center"

                AlignFlexStart ->
                    "flex-start"

                AlignFlexEnd ->
                    "flex-end"

                AlignInherit ->
                    "inherit"

                AlignInitial ->
                    "initial"

                AlignStretch ->
                    "stretch"
        )


listStyleTypeToString : Maybe ListStyleType -> Maybe String
listStyleTypeToString =
    nothingOrJust
        (\val ->
            case val of
                ListStyleTypeNone ->
                    "none"

                ListStyleTypeDisc ->
                    "disc"

                ListStyleTypeCircle ->
                    "circle"

                ListStyleTypeSquare ->
                    "square"

                ListStyleTypeDecimal ->
                    "decimal"

                ListStyleTypeGeorgian ->
                    "georgian"
        )


justifyContentToString : Maybe JustifyContent -> Maybe String
justifyContentToString =
    nothingOrJust
        (\val ->
            case val of
                JustifyContentSpaceBetween ->
                    "space-between"

                JustifyContentSpaceAround ->
                    "space-around"

                JustifyContentCenter ->
                    "center"
        )


textAlignToString : Maybe Alignment -> Maybe String
textAlignToString =
    nothingOrJust
        (\val ->
            case val of
                AlignmentCenter ->
                    "center"

                AlignmentLeft ->
                    "left"

                AlignmentRight ->
                    "right"

                AlignmentJustify ->
                    "justify"
        )


textOverflowToString : Maybe TextOverflow -> Maybe String
textOverflowToString =
    nothingOrJust
        (\val ->
            case val of
                TextOverflowEllipsis ->
                    "ellipsis"
        )


overflowToString : Maybe Overflow.Overflow -> Maybe String
overflowToString =
    nothingOrJust
        (\val ->
            case val of
                Overflow.OverflowAuto ->
                    "auto"

                Overflow.OverflowScroll ->
                    "scroll"

                Overflow.OverflowHidden ->
                    "hidden"

                Overflow.OverflowVisible ->
                    "visible"
        )


flexWrapToString : Maybe FlexWrap -> Maybe String
flexWrapToString =
    nothingOrJust
        (\val ->
            case val of
                FlexWrapWrap ->
                    "wrap"

                FlexWrapNoWrap ->
                    "nowrap"
        )


flexDirectionToString : Maybe FlexDirection -> Maybe String
flexDirectionToString =
    nothingOrJust
        (\val ->
            case val of
                FlexDirectionColumn ->
                    "column"

                FlexDirectionRow ->
                    "row"
        )


nothingOrJust : (a -> b) -> Maybe a -> Maybe b
nothingOrJust fun =
    Maybe.andThen (Just << fun)


unwrapEmptyList : (a -> List b) -> Maybe a -> List b
unwrapEmptyList =
    Maybe.Extra.unwrap []